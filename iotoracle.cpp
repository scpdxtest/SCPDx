// оракул за данни от ИоТ
#include <eosio/eosio.hpp>
#include <eosio/system.hpp>
#include <eosio/time.hpp>
#include <string>
using namespace eosio;
using namespace std;

CONTRACT iotoracle : public contract {

  public:
    using contract::contract;

  TABLE t_reg {
    uint64_t id;
    uint64_t iot_id;
    double value; 
    eosio::time_point_sec reg_at;
    name type;

    uint64_t primary_key() const { return id; }
    uint64_t by_iot() const { return iot_id; }
    uint64_t third_key() const { return reg_at.sec_since_epoch(); }
    double fourth_key() const { return value; }
    uint128_t by_type() const { return ((uint128_t)type.value << 64) + id; }
  };

  typedef eosio::multi_index<
    name("measurereg"), 
    t_reg,
    eosio::indexed_by<
      name("id"),
      eosio::const_mem_fun<
        t_reg,
        uint64_t, 
        &t_reg::primary_key  
      >
    >,
    eosio::indexed_by<
      name("timestamp"),
      eosio::const_mem_fun<
        t_reg,
        uint64_t, 
        &t_reg::third_key
      >  
    >,
    eosio::indexed_by<
      name("values"),
      eosio::const_mem_fun<
        t_reg,
        double, 
        &t_reg::fourth_key
      >  
    >,
    eosio::indexed_by<
      name("iot"),
      eosio::const_mem_fun<
        t_reg,
        uint64_t, 
        &t_reg::by_iot
      >  
    >,
    eosio::indexed_by<
      name("type"),
      eosio::const_mem_fun<
        t_reg,
        uint128_t, 
        &t_reg::by_type
      >  
    >
  > reg_table;

  TABLE m_reg {
    uint64_t id;
    uint64_t iot_id;
    double t_min; 
    double t_max; 
    double t_avg; 
    double t_std; 
    double t_var; 
    double h_min; 
    double h_max; 
    double h_avg; 
    double h_std; 
    double h_var; 
    eosio::time_point_sec reg_at;

    uint64_t primary_key() const { return id; }
    uint64_t by_iot() const { return iot_id; }
    uint64_t third_key() const { return reg_at.sec_since_epoch(); }
  };

  typedef eosio::multi_index<
    name("maritsareg"), 
    m_reg,
    eosio::indexed_by<
      name("id"),
      eosio::const_mem_fun<
        m_reg,
        uint64_t, 
        &m_reg::primary_key  
      >
    >,
    eosio::indexed_by<
      name("timestamp"),
      eosio::const_mem_fun<
        m_reg,
        uint64_t, 
        &m_reg::third_key
      >  
    >,
    eosio::indexed_by<
      name("iot"),
      eosio::const_mem_fun<
        m_reg,
        uint64_t, 
        &m_reg::by_iot
      >  
    >
  > mar_table;


  struct mar_res {
    uint64_t iot_id;
    double t_min; 
    double t_max; 
    double t_avg; 
    double t_std; 
    double t_var; 
    double h_min; 
    double h_max; 
    double h_avg; 
    double h_std; 
    double h_var; 
    string date_str;
  };

  ACTION addmar (name creator, std::vector<mar_res> results) {
    require_auth(get_self());
    mar_table activity(get_self(), get_self().value);    

    for (mar_res i : results) {
      uint64_t newid = activity.available_primary_key();
      time_point_sec dt;
      dt = time_point_sec().from_iso_string(i.date_str);

      activity.emplace( get_self(), [&](auto &e) {
        e.id = newid;
        e.iot_id = i.iot_id;
        e.t_min = i.t_min;
        e.t_max = i.t_max;
        e.t_avg = i.t_avg;
        e.t_std = i.t_std;
        e.t_var = i.t_var;
        e.h_min = i.h_min;
        e.h_max = i.h_max;
        e.h_avg = i.h_avg;
        e.h_std = i.h_std;
        e.h_var = i.h_var;
        e.reg_at = dt;
      });
    }
  }

  struct iot_res {
    double value;
    string date_str;
  };

  ACTION add (name creator, uint64_t iotid, name type, std::vector<iot_res> results) {
    require_auth(get_self());
    reg_table activity(get_self(), get_self().value);    

    for (iot_res i : results) {
      uint64_t newid = activity.available_primary_key();
      time_point_sec dt;
      dt = time_point_sec().from_iso_string(i.date_str);

      activity.emplace( get_self(), [&](auto &e) {
        e.id = newid;
        e.iot_id = iotid;
        e.value = i.value;
        e.reg_at = dt;
        e.type = type;
      });
    }
  }

  struct getLast {
    time_point_sec date;
    double value;
  };

  [[eosio::action]] getLast getlastiorec (name actor, uint64_t iot_id) {
    getLast ret;
    reg_table activity(get_self(), get_self().value);    
    auto idx = activity.get_index<"iot"_n>();
    // if (std::distance(idx.begin(), idx.end()) != 0) {
    auto itr_end = idx.upper_bound(iot_id);
    auto itr_start = idx.lower_bound(iot_id);
    if (itr_end != itr_start) {
      // print("1");
      itr_end--;
      ret.date = itr_end->reg_at;
      ret.value = itr_end->value;
    } else {
      // print("2");
      ret.date = time_point_sec().from_iso_string("2022-01-01T00:00:00");
      ret.value = 0;
    }
    return ret;
  }

  ACTION getLast getlastrec (name actor, uint64_t iot_id) {
    getLast ret;
    reg_table activity(get_self(), get_self().value);    
    auto idx = activity.get_index<"iot"_n>();
    auto itr_end = idx.upper_bound(iot_id);
    auto itr_start = idx.lower_bound(iot_id);
    if (itr_end != itr_start) {
      itr_end--;
      ret.date = itr_end->reg_at;
      ret.value = itr_end->value;
    } else {
      ret.date = time_point_sec().from_iso_string("2022-01-01T00:00:00");
      ret.value = 0;
    }
    action (
      permission_level{get_self(), "active"_n},
      name(actor),
      "callback"_n,
      std::make_tuple(get_self(), ret.value, ret.date)
    ).send();
  }

// call-back function sample
  ACTION callback (const name& caller, const double& value, const string& timestamp) {
    string tm = timestamp;
    double val = value;
    print("According to myOracle at ", tm, " ", " value is ", val);
// implement your decision making algorithm here ...    
  }


  ACTION clearallact(name user, uint64_t plimit) {
    reg_table activities(get_self(), get_self().value);
    auto itr = activities.begin();
    auto count = 0;
    for (auto itr = activities.begin(); itr != activities.end() && count != plimit; ) {
      itr = activities.erase(itr);
      print(".");
      count++;
    };
  }

};

