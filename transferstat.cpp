#include <eosio/eosio.hpp>
#include <eosio/system.hpp>
#include <eosio/time.hpp>
#include <eosio/asset.hpp>
#include <eosio/symbol.hpp>
#include <eosio/singleton.hpp>
#include <string>
using namespace eosio;
using namespace std;

CONTRACT transferstat : public contract {

  public:
    using contract::contract;

  transferstat( name receiver, name code, datastream<const char*> ds) : 
    contract(receiver, code, ds) {}

  TABLE ledger {
    uint64_t id;
    name from;
    name to; 
    eosio::asset qty;
    string memo;
    eosio::time_point_sec time;
    name token;

    uint64_t primary_key() const { return id; }
    uint64_t time_key() const { return time.sec_since_epoch(); }
    uint64_t from_key() const { return from.value; }
    uint64_t to_key() const { return to.value; }
    uint64_t token_key() const { return token.value; }
  };

  typedef eosio::multi_index<
    name("accledger"), 
    ledger,
    eosio::indexed_by<
      name("id"),
      eosio::const_mem_fun<
        ledger,
        uint64_t, 
        &ledger::primary_key  
      >
    >,
    eosio::indexed_by<
      name("timestamp"),
      eosio::const_mem_fun<
        ledger,
        uint64_t, 
        &ledger::time_key
      >  
    >,
    eosio::indexed_by<
      name("from"),
      eosio::const_mem_fun<
        ledger,
        uint64_t, 
        &ledger::from_key
      >  
    >,
    eosio::indexed_by<
      name("to"),
      eosio::const_mem_fun<
        ledger,
        uint64_t, 
        &ledger::to_key
      >  
    >,
    eosio::indexed_by<
      name("token"),
      eosio::const_mem_fun<
        ledger,
        uint64_t, 
        &ledger::token_key
      >  
    >    
  > ledger_table;

  [[eosio::on_notify("eosio.token::transfer")]] void depo (name from, name to, eosio::asset quantity, string memo) {
    // print("in notify");
    std::string tkn = quantity.symbol.code().to_string();
    std::transform(tkn.begin(), tkn.end(), tkn.begin(),[](unsigned char c){ return std::tolower(c); });    
    name token_symbol = name(tkn);
    print(quantity.symbol.code().to_string(), tkn);

    ledger_table ledgerTable(get_self(), get_self().value);

    ledgerTable.emplace( get_self(), [&](auto& new_row){
      new_row.id = ledgerTable.available_primary_key();
      new_row.from = from;
      new_row.to = to;
      new_row.memo = memo;
      new_row.token = token_symbol;
      new_row.time = time_point(current_time_point());
      new_row.qty = quantity;
    });
  }

    ACTION clearallsts(name user) {
    check(has_auth(get_self()), "You have no authority to clear documents table!");
    ledger_table activities(get_self(), get_self().value);
    for (auto itr = activities.begin(); itr != activities.end(); ) {
      itr = activities.erase(itr);
      print(".");
    };
  }

};
