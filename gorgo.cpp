#include <eosio/eosio.hpp>
#include <eosio/system.hpp>
#include <eosio/time.hpp>
#include <string>
using namespace eosio;
using namespace std;

CONTRACT gorgo : public contract {

  public:
    using contract::contract;

  TABLE activity {
    uint64_t id;
    name chain;
    std::string endpoint; 
    eosio::time_point_sec checked_at;
    bool status;

    uint64_t primary_key() const { return id; }
    uint64_t third_key() const { return checked_at.sec_since_epoch(); }
    uint64_t status_key() const {
      uint64_t ret = 1;
      if (!status) { ret = 0; };
      print(ret);
      return ret;
    }
  };

  typedef eosio::multi_index<
    name("activityreg"), 
    activity,
    eosio::indexed_by<
      name("id"),
      eosio::const_mem_fun<
        activity,
        uint64_t, 
        &activity::primary_key  
      >
    >,
    eosio::indexed_by<
      name("timestamp"),
      eosio::const_mem_fun<
        activity,
        uint64_t, 
        &activity::third_key
      >  
    >,
    eosio::indexed_by<
      name("status"),
      eosio::const_mem_fun<
        activity,
        uint64_t, 
        &activity::status_key
      >  
    >
  > activity_table;

  ACTION add (name creator, name chain, string endpoint, bool status) {
    require_auth(creator);
    activity_table activity(get_self(), get_self().value);    
    uint64_t newid = activity.available_primary_key();
    eosio::time_point_sec timestamp = time_point(current_time_point());

    activity.emplace( get_self(), [&](auto &e) {
      e.id = newid;
      e.chain = chain;
      e.endpoint = endpoint;
      e.checked_at = timestamp;
      e.status = status;
    });
  }

  ACTION clearallact(name user) {
    activity_table activities(get_self(), get_self().value);
    for (auto itr = activities.begin(); itr != activities.end(); ) {
      itr = activities.erase(itr);
      print(".");
    };
  }

};


