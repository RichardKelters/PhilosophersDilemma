var handle Socket,  Win.
var char Info, Philosophor.
var int Eat, Requests, Id.

// userinterface
define frame F
    Info  format "x(40)"
.

create window Win.
Win:hidden = false.
Win:visible = true.
Win:width = 45.
Win:height = 3.
current-window = Win.
view frame F in window Win.

// Functions

function Log returns logical (Note as character):
    log-manager:logfile-name = "dilemma.log".
    log-manager:write-message(substitute("&1 &2 &3"
                                        ,Id // class scoped value
                                        ,program-name(2)
                                        ,Note
                                        )
                             ,"Philos"
                             ).
end function.

function ShowInfo returns logical (Note as character):
    Log(substitute("ShowInfo: &1",Note)).
    do with frame F:
        Info:screen-value = Note.
    end.
end function.

function WriteData returns logical (Socket as handle,Note as character):
    var memptr Data.
    var int Bytes.
    Bytes = length(Note) + 1.
    Log(substitute("Bytes: &1 Data: &2",Bytes,Note)).
    set-size(Data) = Bytes.
    put-string(Data,1) = Note.
    Socket:write(Data,1,Bytes).
    Log("WriteData").
    finally:
        set-size(Data) = 0.
    end finally.
end function.

function ReadData returns character (Socket as handle):
    var memptr Data.
    var int Bytes.
    Log("ReadData").
    Bytes = Socket:get-bytes-available().
    set-size(Data) = Bytes.
    Socket:read(Data,1,Bytes).
    Log(substitute("Bytes: &1 Data: &2",Bytes,get-string(Data,1))).
    return get-string(Data,1).
    finally:
        set-size(Data) = 0.
    end finally.
end function.

function Connect returns handle (CallBackProcedure as character,Port as integer):
    var handle Socket.
    var int i.
    Log(substitute("Connect port: &1",Port)).
    create socket Socket.
    Socket:set-read-response-procedure(CallBackProcedure).
    do while not Socket:connected()  i = 1 to 10:
        pause 1 no-message.
        Socket:connect(substitute("-S &1",Port)).
    end.
    return Socket.
end function.

    
// connect to the waiter
Socket = Connect ("Response",13002).

repeat while Eat lt 3 and Requests lt 25 and Socket:connected():

    wait-for go, end-error of frame F pause .1 .
    WriteData (Socket,"request to eat").
    Requests += 1.
end.

Socket:disconnect().
delete object Socket.
quit.

procedure Response:
    var int Bytes.
    var memptr Data.
    var char Response, Note.

    if not self:connected()
    then do:
        delete object self.
        return.
    end.

    Response = ReadData(self).

    ShowInfo ( substitute("response: &1",Response) ).

    case Response:
        when "allowed to eat"
        then do:
            Eat += 1.
            ShowInfo( substitute("&1 eating meal &2",Philosophor,Eat) ).
            pause 1 no-message.
            Note = "meal finished".
            WriteData (Socket,Note).
            Note = substitute("meal finished meal=&1 requests=&2",Eat,Requests).
            ShowInfo(Note).
        end.
        otherwise do:
            if Response begins "philosopher"
            then do:
                Philosophor = Response.
                Id = integer(entry(2,Philosophor," ")).
                Win:column = Win:width * Id.
                Win:row = 3.
            end.
        end.
    end case.
    finally:
        set-size(Data) = 0.
    end finally.
end procedure.

