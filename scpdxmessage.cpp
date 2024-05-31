#include <eosio/eosio.hpp>
#include <eosio/system.hpp>
#include <eosio/time.hpp>
#include <eosio/asset.hpp>
#include <eosio/symbol.hpp>
#include <eosio/singleton.hpp>
#include <string>
#include <vector>

using namespace eosio;
using namespace std;

CONTRACT scpdxmessage : public contract {
  public:

  using contract::contract;

  TABLE message {
    uint64_t id;
    name from;
    name to;
    std::string text;
    eosio::time_point_sec send_at;
    eosio::time_point_sec read_at;
    uint8_t type;

    uint64_t primary_key() const { return id; }
    uint64_t get_from_key() const { return from.value; }
    uint64_t get_to_key() const { return to.value; }
  };

  typedef eosio::multi_index<
    name("messages"), 
    message,
    eosio::indexed_by<
      name("id"),
      eosio::const_mem_fun<
        message,
        uint64_t, 
        &message::primary_key  
      >
    >,
    eosio::indexed_by<
      name("from"),
      eosio::const_mem_fun<
        message,
        uint64_t, 
        &message::get_from_key
      >  
    >,
    eosio::indexed_by<
      name("to"),
      eosio::const_mem_fun<
        message,
        uint64_t, 
        &message::get_to_key
      >
    >
  > message_table;

  TABLE notification {
    uint64_t id;
    name from;
    name to;

    uint64_t primary_key() const { return id; }
    uint64_t get_to_key() const { return to.value; }  
  };

  typedef eosio::multi_index<
    name("ntifications"), 
    notification,
    eosio::indexed_by<
      name("to"),
      eosio::const_mem_fun<
        notification,
        uint64_t,
        &notification::get_to_key
      >
    >,
      eosio::indexed_by<
      name("id"),
      eosio::const_mem_fun<
        notification,
        uint64_t,
        &notification::primary_key
      >
    >
  > notification_table;

  void makePayment (name from) {
    // print("trace payment", from);
    eosio::symbol token_symbol("SYS", 4);
    asset qty(1, token_symbol);
    action (
      permission_level{name(from), "active"_n},
      name("eosio.token"),
      name("transfer"),
      std::make_tuple(from, name("scpdxmessage"), qty, std::string("send message payment!"))
    ).send();
  }

  struct [[eosio::table]] account {
    eosio::asset balance;
    uint64_t primary_key()const { return balance.symbol.code().raw(); }
  };

  typedef eosio::multi_index< "accounts"_n, account > accounts;

  static eosio::asset get_balance(eosio::name owner, eosio::symbol_code sym_code )
  {
    accounts accountstable("eosio.token"_n, owner.value );
    const auto& ac = accountstable.get( sym_code.raw() );
    return ac.balance;
  }

  ACTION sendmsg(const name from, const name to, const std::string msg) {
    // require_auth(from);

    check(msg.size() > 0, "Empty message");
    // eosio::symbol_code code("SYS");
    // asset account_balance = get_balance(from, code);
    // print("account balance", account_balance);
    // check(account_balance.amount >= 1, "not enough tokens!");

    notification_table notifications(get_self(), get_self().value);
    message_table messages(get_self(), get_self().value);    
    
    uint64_t newid = messages.available_primary_key();
    // print("msg id", newid);
    // uint64_t newnotid = notifications.available_primary_key();

    notifications.emplace(from, [&](auto &n) {
      n.id = newid;
      n.from = from;
      n.to = to;
    });

    messages.emplace(from, [&](auto &m) {
      m.id = newid;
      m.from = from;
      m.to = to;
      m.text = msg;
      m.send_at = time_point(current_time_point());
    });
    // makePayment(from);
  }

  struct readmsg_return {
    std::string text;
    std::string date;
  };

  [[eosio::action]] readmsg_return receivemsg(const name to, uint64_t id) {
    require_auth(to);

    notification_table notifications(get_self(), get_self().value);
    auto itr_notif = notifications.find(id);
    check(itr_notif != notifications.end(), "Notification not found");
    const auto &notif = *itr_notif;
    
    check(notif.to == to, "Message not to your account");
    
    message_table messages(get_self(), get_self().value);    
    auto itr_msg = messages.find(id);
    check(itr_msg != messages.end(), "Message not found");
    
    notifications.erase(itr_notif);
    // messages.erase(itr_msg);
    readmsg_return ret;
    ret.text = itr_msg->text;
    ret.date = itr_msg->send_at.to_string();

    messages.modify(itr_msg, get_self(), [&](auto& new_row) {
      new_row.read_at = time_point(current_time_point());
    });

    return (ret);
  }

  ACTION erasemsg(const name from, uint64_t id) {
    require_auth(from);

    notification_table notifications(get_self(), get_self().value);
    auto itr_notif = notifications.find(id);
    check(itr_notif != notifications.end(), "Notification not found");
    const auto &notif = *itr_notif;

    check(notif.from == from, "Message not from your account");
    
    message_table messages(get_self(), get_self().value);
    auto itr_msg = messages.find(id);
    check(itr_msg != messages.end(), "Message not found");
    
    notifications.erase(itr_notif);
    messages.erase(itr_msg);
  }

  ACTION testaction(name user) {
    print("--------> test action <--------------");
  }

  ACTION clearall(name user) {
    check(has_auth(get_self()), "You have no authority to clear documents table!");
    message_table messages(get_self(), get_self().value);
    for (auto itr = messages.begin(); itr != messages.end(); ) {
      itr = messages.erase(itr);
      print(".");
    };
    notification_table notifications(get_self(), get_self().value);
    for (auto itr = notifications.begin(); itr != notifications.end(); ) {
      itr = notifications.erase(itr);
      print(".");
    };
  }

};
