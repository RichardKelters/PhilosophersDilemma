var handle Socket,  Win.
var char Info, Philosophor.
var int Eat,Requests.

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
function ShowInfo returns logical (Note as character):
    do with frame F:
        Info:screen-value = Note.
    end.
end function.

function WriteData returns logical (Socket as handle,Note as character):
    var memptr Data.
    var int Bytes.
    Bytes = length(Note) + 1.
    set-size(Data) = Bytes.
    put-string(Data,1) = Note.
    Socket:write(Data,1,Bytes).
    finally:
        set-size(Data) = 0.
    end finally.
end function.

function ReadData returns character (Socket as handle):
    var memptr Data.
    var int Bytes.
    Bytes = Socket:get-bytes-available().
    set-size(Data) = Bytes.
    Socket:read(Data,1,Bytes).
    return get-string(Data,1).
    finally:
        set-size(Data) = 0.
    end finally.
end function.

function Connect returns handle (CallBackProcedure as character,Port as integer):
    var handle Socket.
    create socket Socket.
    Socket:set-read-response-procedure(CallBackProcedure).
    Socket:connect(substitute("-S &1",Port)).
    return Socket.
end function.

// connect to the waiter
Socket = Connect ("Response",13002).

repeat while Eat lt 3:

    wait-for go, end-error of frame F pause .5 .
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
            Note = substitute("meal finished requests=&1",Requests).
            ShowInfo(Note).
        end.
        otherwise do:
            if Response begins "philosopher"
            then do:
                Philosophor = Response.
                Win:column = Win:width * integer(entry(2,Philosophor," ")).
                Win:row = 3.

            end.
        end.
    end case.
    finally:
        set-size(Data) = 0.
    end finally.
end procedure.

