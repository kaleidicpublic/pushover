module kaleidic.api.pushover;
import std.stdio;
import std.json;
import std.net.curl;
import std.exception:Exception,enforce,assumeUnique;
import std.conv:to;
import std.algorithm:countUntil,map,each;
import std.traits:EnumMembers;
import std.array:array,appender;
import std.format:format;
import std.variant:Algebraic;
import std.typecons:Nullable;
import std.datetime:SysTime,DateTime;
/**
    Implemented in the D Programming Language 2016 by Laeeth Isharc and Kaleidic Associates Advisory UK Limited
    Boost Licensed
    Use at your own risk - this is not tested at all.

    API for pushover notification API
    https://pushover.net/
*/
debug=1;

static this()
{
    PushoverMessageSounds=[ "pushover",
                            "bike",
                            "bugle",
                            "cashregister",
                            "classical",
                            "cosmic",
                            "falling",
                            "gamelan",
                            "incoming",
                            "intermission",
                            "magic",
                            "mechanical",
                            "pianobar",
                            "siren",
                            "spacealarm",
                            "tugboat",
                            "alien",
                            "climb",
                            "persistent",
                            "echo",
                            "updown",
                            "none"  ];

}

string joinUrl(string url, string endpoint)
{
    enforce(url.length>0, "broken url");
    if (url[$-1]=='/')
        url=url[0..$-1];
    return url~"/"~endpoint;
}

struct ApplicationKey
{
    string key;
    alias key this;
}
struct UserKey
{
    string key;
    alias key this;
}

struct GroupKey
{
    string key;
    alias key this;
}

struct APIToken
{
    string token;
    alias token this;
}

struct DeviceName
{
    string name;
    alias name this;
}
struct PushoverAPI
{
    string endpoint = "https://api.pushover.net/1/";
    APIToken token;
    UserKey userKey=null.UserKey;

    this(APIToken token)
    {
        this.token=token;
    }
    this(APIToken token, UserKey userKey)
    {
        this.token=token;
        this.userKey=userKey;
    }
}

enum PushoverMessagePriority
{
    lowest=-2,
    low=-1,
    normal=0,
    high=1,
    emergency=2, 
}

string[] PushoverMessageSounds;

struct PushoverMessage
{
    string messageText=null;
    DeviceName device=null.DeviceName;
    string title=null;
    string url=null;
    string urlTitle=null;
    Nullable!PushoverMessagePriority priority;
    Nullable!SysTime timeStamp;
    string sound=null;

    this(string messageText)
    {
        this.messageText=messageText;
    }
}

auto ref setMessage(ref PushoverMessage message, string messageText)
{
    message.messageText=messageText;
    return message;
}

auto ref setDevice(ref PushoverMessage message, DeviceName device)
{
    message.device=device.name;
    return message;
}

auto ref setTitle(ref PushoverMessage message, string title)
{
    message.title=title;
    return message;
}

auto ref setUrl(ref PushoverMessage message, string url)
{
    message.url=url;
    return message;
}

auto ref setUrlTitle(ref PushoverMessage message, string urlTitle)
{
    message.urlTitle=urlTitle;
    return message;
}
auto ref setPriority(ref PushoverMessage message, PushoverMessagePriority priority)
{
    message.priority=priority;
    return message;
}

auto ref setPriority(ref PushoverMessage message, int priority)
{
    message.priority=priority.to!PushoverMessagePriority;
    return message;
}

auto ref setTimeStamp(ref PushoverMessage message, DateTime timeStamp)
{
    message.timeStamp=cast(SysTime) timeStamp;
    return message;
}

auto ref setTimeStamp(ref PushoverMessage message, SysTime timeStamp)
{
    message.timeStamp=timeStamp;
    return message;
}

auto ref setSound(ref PushoverMessage message, string sound)
{
    message.sound=sound;
    return message;
}

auto sendMessage(PushoverAPI api, PushoverMessage message, UserKey user=null.UserKey)
{
    JSONValue params = ["message": message.messageText];
    if (user.key.length==0)
    {
        enforce(api.userKey.key.length>0,"PushOverAPI.sendMessage - you must specify either a user in the sendMessage call or in the API constructor");
        params["user"]=api.userKey.key;
    }
    else
    {
        params["user"] = user.key;
    }
    if (message.device.name !is null)
        params["device"]=message.device.name;
    if (message.title !is null)
        params["title"] = message.title;
    if (message.url !is null)
        params["url"] = message.url;
    if (message.urlTitle !is null)
        params["url_title"] = message.urlTitle;
    if (!message.priority.isNull)
        params["priority"] = message.priority;
    if (!message.timeStamp.isNull)
        params["time_stamp"] = message.timeStamp.toUnixTime;
    if (message.sound !is null)
        params["sound"] = message.sound;
    return api.request("messages.json", HTTP.Method.post,params);
}

auto listGroupMembers(PushoverAPI api, GroupKey groupKey)
{
    return api.request("groups/"~groupKey~".json",HTTP.Method.get);
}


auto addUserToGroup(PushoverAPI api, UserKey userKey, GroupKey groupKey, DeviceName device=null.DeviceName, string memo=null)
{
    import std.uri:encodeComponent;
    JSONValue params;
    params["user"] = userKey.key;
    if (device.name !is null)
        params["device"] = device.name;
    if (memo !is null)
        params["memo"] = memo;
    return api.request("groups/"~groupKey.key.encodeComponent~"/add_user.json",HTTP.Method.post,params);
}

auto removeUserFromGroup(PushoverAPI api, UserKey userKey, GroupKey groupKey)
{
    import std.uri:encodeComponent;
    JSONValue params;
    params["user"]=userKey;
    return api.request("groups/"~groupKey.key.encodeComponent~"/delete_user.json",HTTP.Method.post,params);
}

auto disableUser(PushoverAPI api, UserKey userKey, GroupKey groupKey)
{
    import std.uri:encodeComponent;
    JSONValue params;
    params["user"]=userKey;
    return api.request("groups/"~groupKey.key.encodeComponent~"/disable_user.json",HTTP.Method.post,params);
}

auto enableUser(PushoverAPI api, UserKey userKey, GroupKey groupKey)
{
    import std.uri:encodeComponent;
    JSONValue params =[ "user": userKey.key ];
    return api.request("groups/"~groupKey.key.encodeComponent~"/enable_user.json",HTTP.Method.post,params);
}

auto renameGroup(PushoverAPI api, string oldName, string newName)
{
    import std.uri:encodeComponent;
    JSONValue params;
    params["name"]=newName;
    return api.request("groups/"~oldName.encodeComponent~"/rename.json",HTTP.Method.post,params);
}
auto listSounds(PushoverAPI api)
{
    return api.request("sounds.json",HTTP.Method.get);
}

auto validate(PushoverAPI api, UserKey user, DeviceName device=null.DeviceName)
{
    JSONValue params;
    params["user"]=user.key;
    if(device.length>0)
        params["device"]=device.name;
    return api.request("users/validate.json",HTTP.Method.post,params);
}

auto checkReceipt(PushoverAPI api, string receipt)
{
    import std.uri:encodeComponent;
    return api.request("receipts/"~receipt.encodeComponent~".json");
}

auto cancelEmergencyDelivery(PushoverAPI api, string receipt)
{
    import std.uri:encodeComponent;
    return api.request("receipts/"~receipt.encodeComponent~"/cancel.json");
}

auto assignLicense(PushoverAPI api, string email=null, string os=null)
{
    JSONValue params;
    if (email !is null)
        params["email"]=email;
    if (os !is null)
        params["os"]=os;
    return api.request("licenses/assign.json");
}

string stripQuotes(string s)
{
    if (s.length<2)
        return s;
    if (s[0]=='"')
        s=s[1..$];
    if (s.length<1)
        return s;
    if (s[$-1]=='"')
        s=s[0..$-1];
    return s;
}

auto request(PushoverAPI api, string url, HTTP.Method method=HTTP.Method.get, JSONValue params=JSONValue(null))
{
    import std.array:appender;
    import std.uri:encodeComponent;
    import std.conv:to;
    import std.algorithm:canFind;
    enforce(api.token.length>0,"no token provided");
    auto paramsData=appender!string;
    paramsData.put("token=");
    paramsData.put(api.token.encodeComponent);
    paramsData.put("&");
    if (params.type != JSON_TYPE.OBJECT) 
    {
        params=["user": api.userKey.key];
    }
    else if (!params.object.keys.canFind("user"))
    {
        params["user"]=api.userKey;
    }


    if (params.type == JSON_TYPE.OBJECT)
    {
        foreach(i,param;params.object.keys)
        {
            if (i>0)
                paramsData.put("&");
            paramsData.put(param.to!string.encodeComponent);
            paramsData.put("=");
            paramsData.put(params[param].toString.stripQuotes.encodeComponent);
        }
    }
    debug
    {
        writefln("request: %s",paramsData.data);
    }
    url=api.endpoint.joinUrl(url);
    auto client=HTTP(url);
    auto response=appender!(ubyte[]);
    client.method=method;
    client.setPostData(cast(void[])paramsData.data,"application/x-www-form-urlencoded");
    client.onReceive = (ubyte[] data)
    {
        response.put(data);
        return data.length;
    };
    client.perform();                 // rely on curl to throw exceptions on 204, >=500
    debug writeln(cast(string)response.data);
    return parseJSON(cast(string)response.data);
}

    
unittest
{
    import std.datetime:Clock;

    enum applicationKey = "set me".ApplicationToken;
    enum targetUserKey = "set me".UserKey;
    enum groupKey = "set me".GroupKey;
    enum targetUserMemo ="memo field here";
    
    auto api=PushoverAPI(applicationToken);
    writefln("validate target user: %s",api.validate(targetUserKey));
    writeln("result of adding target user to group:",api.addUserToGroup(targetUserKey,groupKey,null.DeviceName,targetUserMemo));
    PushoverMessage message;

    message=message.setMessage("as the CNBC anchor said, is buying GS here like D&G on sale?")
        .setTitle("Kaleidic Market Alert - GS")
        .setUrl("kaleidic.io")
        .setUrlTitle("GS chart")
        .setPriority(PushoverMessagePriority.high)
        .setTimeStamp(Clock.currTime());
    writefln("%s",message);
    auto ret=api.sendMessage(message,targetUserKey);
    writefln("message status: %s",ret["status"]);
    writefln("message request: %s",ret["request"]);
}

