// Децентрализирана, базирана на блокчейн технологии система за обмен и продажба на големи информационни масиви.
#include <eosio/eosio.hpp>
#include <eosio/system.hpp>
#include <eosio/time.hpp>
#include <eosio/asset.hpp>
#include <eosio/symbol.hpp>
#include <eosio/singleton.hpp>
#include <string>
using namespace eosio;
using namespace std;

CONTRACT ipfsstoreooo : public contract {

  public:
    using contract::contract;

    struct [[eosio::table]] myvar {
      bool payable;
    } default_settings;

    ipfsstoreooo( name receiver, name code, datastream<const char*> ds) : 
      contract(receiver, code, ds),
      settings_instance(receiver, receiver.value) {}

    using singleton_type = eosio::singleton<"myvar"_n, myvar>;
    singleton_type settings_instance;

  TABLE store {
    uint64_t id;
    std::string filename;
    std::string hash; 
    uint64_t size;
    name created_by;
    eosio::time_point_sec created_at;
    eosio::asset price;
    bool is_available;
    string description;

    uint64_t primary_key() const { return id; }
    uint64_t third_key() const { return created_at.sec_since_epoch(); }
    uint64_t available_key() const {
      uint64_t ret = 1;
      if (!is_available) { ret = 0; };
      print(ret);
      return ret;
    }
  };

  typedef eosio::multi_index<
    name("ipfsregister"), 
    store,
    eosio::indexed_by<
      name("id"),
      eosio::const_mem_fun<
        store,
        uint64_t, 
        &store::primary_key  
      >
    >,
    eosio::indexed_by<
      name("timestamp"),
      eosio::const_mem_fun<
        store,
        uint64_t, 
        &store::third_key
      >  
    >,
    eosio::indexed_by<
      name("available"),
      eosio::const_mem_fun<
        store,
        uint64_t, 
        &store::available_key
      >  
    >
  > store_table;

  TABLE activity {
    uint64_t uid;
    name actor;
    time_point_sec timestamp;
    uint64_t act;
// 1 - add file
// 2 - get file    
    uint64_t object_id;

    uint64_t primary_key() const { return uid; }
    uint64_t time_key() const { return timestamp.sec_since_epoch(); }
    uint64_t action_key() const { return act; }
    uint64_t object_key() const { return object_id; }
    uint64_t actor_key() const { return actor.value; }
  };

  typedef eosio::multi_index<
    name("activityreg"), 
    activity,
    eosio::indexed_by<
      name("uid"),
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
        &activity::time_key
      >  
    >,
    eosio::indexed_by<
      name("actions"),
      eosio::const_mem_fun<
        activity,
        uint64_t, 
        &activity::action_key
      >  
    >,
    eosio::indexed_by<
      name("objects"),
      eosio::const_mem_fun<
        activity,
        uint64_t, 
        &activity::object_key
      >  
    >,
    eosio::indexed_by<
      name("actors"),
      eosio::const_mem_fun<
        activity,
        uint64_t, 
        &activity::actor_key
      >  
    >  
  > activity_table;

  struct [[eosio::table]] account {
  eosio::asset    balance;

  uint64_t primary_key()const { return balance.symbol.code().raw(); }
  };
  typedef eosio::multi_index< "accounts"_n, account > accounts;

  static eosio::asset get_balance(eosio::name owner, eosio::symbol_code sym_code )
  {
    accounts accountstable("eosio.token"_n, owner.value );
    const auto& ac = accountstable.get( sym_code.raw() );
    return ac.balance;
  }

  struct addfile_return
  {
    uint64_t size;
    eosio::time_point_sec timestamp;
  };

  [[eosio::action]] addfile_return addfile (name creator, string filename, string hash, uint64_t size, string description, eosio::asset price, bool is_available) {
    require_auth(creator);
    check(price.is_valid(), "Invalid token!");
    store_table files(get_self(), get_self().value);    
    uint64_t newid = files.available_primary_key();
    eosio::time_point_sec timestamp = time_point(current_time_point());

    files.emplace( get_self(), [&](auto &e) {
      e.id = newid;
      e.hash = hash;
      e.filename = filename;
      e.price = price;
      e.created_at = timestamp;
      e.created_by = creator;
      e.description = description;  
      e.size = size;
      e.is_available = is_available;
    });
    
    activity_table activities(get_self(), get_self().value);    
    uint64_t new_act_id = activities.available_primary_key();
    
    activities.emplace( get_self(), [&](auto &a) {
      a.uid = new_act_id;
      a.actor = creator;
      a.timestamp = timestamp;
      a.act = 1;
      a.object_id = newid;
    });

    addfile_return ret;
    ret.size = newid;
    ret.timestamp = timestamp; 
    return ret;
  }

  struct getfile_return {
    string hash;
    string filename;
    uint64_t size;
    eosio::time_point_sec timestamp;
  };

  [[eosio::action]] getfile_return getfile (name actor, uint64_t id) {
    check(has_auth(actor), "you have no rights to get files!");
    store_table files(get_self(), get_self().value);    
    auto itr = files.find(id);
    check(itr != files.end(), "File ID not found");

    if (read_payable()) {
      eosio::symbol_code code_sym("SYS");
      asset account_balance = get_balance(actor, code_sym);
      print("account balance", account_balance);
      check(account_balance.amount >= itr->price.amount, "Not enough tokens!");

      name to = itr->created_by;
      asset price = itr->price;
      action (
        permission_level{name(actor), "active"_n},
        name("eosio.token"),
        name("transfer"),
        std::make_tuple(actor, to, price, std::string("payment for" + itr->filename))
      ).send();
    };

    activity_table activities(get_self(), get_self().value);  
    auto itract = activities.end();  
    uint64_t new_act_id = activities.available_primary_key();
    eosio::time_point_sec tm = time_point(current_time_point());
    activities.emplace( get_self(), [&](auto &a) {
      a.uid = new_act_id;
      a.actor = actor;
      a.timestamp = tm;
      a.act = 2;
      a.object_id = id;
    });

    getfile_return ret;
    ret.hash = itr->hash;
    ret.filename = itr->filename;
    ret.size = itr->size;
    ret.timestamp = tm;
    return ret;
  }  

  struct payret {
    bool status;
  };

  [[eosio::action]] payret paystatus () {
    require_auth(name("ipfsstoreooo"));
    payret ret;
    ret.status = read_payable();
    return ret;
  }  

  [[eosio::action]] uint8_t checkuser (name actor) {
    print(get_self());
    require_auth(actor);
    uint8_t ret = 0;
    if (has_auth(actor)) {
      ret = 1;
    };
    return ret;
  }  

  ACTION testuser() {
    print(get_self());
  }

  ACTION clearallact(name user) {
    // check(has_auth(get_self()), "You have no authority to clear documents table!");
    activity_table activities(get_self(), get_self().value);
    for (auto itr = activities.begin(); itr != activities.end(); ) {
      itr = activities.erase(itr);
      print(".");
    };
  }

  ACTION replaystore(name user) {
    // check(has_auth(get_self()), "You have no authority to clear documents table!");
    store_table files(get_self(), get_self().value);
    auto cnt = 0;
    for (auto itr = files.begin(); itr != files.end(); ) {
      files.modify(itr, get_self(), [&](auto& new_row) {
        new_row.size = itr->size;
      });
      print(".");
      itr++;
      cnt++;
    };
    print(cnt, " records");
  }

  ACTION setvar (name author, bool payable) {
    require_auth(name("ipfsstoreooo"));
    auto var_stored = settings_instance.get_or_create(get_self(), default_settings);
    var_stored.payable = payable;
    settings_instance.set(var_stored, get_self());

    print("read *** singleton: ", read_payable());
  }

  bool read_payable () {
    if (settings_instance.exists()) {
      return settings_instance.get().payable;
    } else {
      return false;
    }
  }
};

// mongosh --host 195.230.127.227 --port 60017 myDB

// при съсздаване на акаунтите:
// cleos -u http://195.230.127.227:8012 set account permission ira active '{"threshold": 1,"keys": [{"key": "EOS6kZ9W2NBpEMVYdW2LjLNhq4XBKmPnw1AwaCLBAJ6hUBVgGzqPk","weight": 1}],"accounts": [{"permission": {"actor": "ipfsstoreooo","permission": "eosio.code"},"weight": 1}]}' owner -p ira
// cleos -u http://195.230.127.227:8012 set account permission boni active '{"threshold": 1,"keys": [{"key": "EOS7HFnPuomPUXdJQNoUVAmNPdSDj8JBNm58ahNavCS3PawTa3kTh","weight": 1}],"accounts": [{"permission": {"actor": "ipfsstoreooo","permission": "eosio.code"},"weight": 1}]}' owner -p boni
// cleos -u http://195.230.127.227:8012 set account permission scpdxmobile1 active '{"threshold": 1,"keys": [{"key": "EOS6vigVghp5ceEECi2ZsxLD6A55oBNA3E3AiJodLb4wsRTX8A9V6","weight": 1}],"accounts": [{"permission": {"actor": "ipfsstoreooo","permission": "eosio.code"},"weight": 1}]}' owner -p scpdxmobile1
// cleos -u http://195.230.127.227:8012 set account permission boni1ooooooo active '{"threshold": 1,"keys": [{"key": "EOS6uxVHZSfLGqj4gk6nEr2HXSEQPbf2CjDCzmLBbE3HXDLQe6DWA","weight": 1}],"accounts": [{"permission": {"actor": "ipfsstoreooo","permission": "eosio.code"},"weight": 1}]}' owner -p boni1ooooooo

// github new token
// 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

// gitlab codes
// f65ea5f34a7f83be
// fe888a2315103db3
// c95c8acdce89b93f
// 8bf8e42d1342dafd
// 7bfe3702c69024a9
// 2c2d0520a1a804c2
// 651eaa03836c11cc
// 388372605d24e8ff
// 680edd6c76b75625
// a851488e0e160617

// cleos -u http://195.230.127.227:8012 push action eosio.token create '[ "eosio", "100000000000 TEST" ]' -p eosio.token@active
// cleos -u http://195.230.127.227:8012 push action eosio.token issue '[ "eosio", "100000000000 TEST", "memo" ]' -p eosio@active

// private  5JAsi14cBiFK9kx3WzoZPJaFUrUZcnTnSXkUWxKgdpKGY1e65re 
// public   EOS7HFnPuomPUXdJQNoUVAmNPdSDj8JBNm58ahNavCS3PawTa3kTh

// mobile user
//          EOS6vigVghp5ceEECi2ZsxLD6A55oBNA3E3AiJodLb4wsRTX8A9V6
//          5HqTbojJyaKEdFfX8BhCLBYY3Wkh1SqyYdq2EWkvDqLHXeDqwNk

// cleos -u http://192.168.1.220:8066 system newaccount eosio --transfer boni EOS7R8AgiY9Kp44JSDq8CGpMXgPyPgQSmoSCe5wsEy1zRWwnrW8Ak --stake-net "100000000.0000 SYS" --stake-cpu "100000000.0000 SYS" --buy-ram-kbytes 8192
