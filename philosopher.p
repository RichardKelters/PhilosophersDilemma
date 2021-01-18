var handle Socket,  Win.
var char Info, Note, Philosophor.
var int Eat, Bytes.
var memptr Data.

define frame F 
    Info at row 1 col 1 format "x(40)"
.

create window Win.
Win:hidden = false.
Win:visible = true.
Win:width = 45.
Win:height = 3.
current-window = Win.
view frame F in window Win.

run Connect (13000,output Socket).

repeat while Eat lt 3:
    wait-for go of frame F pause 1.
    Note = substitute("request to eat").
    Bytes = length(Note) + 1.
    set-size(Data) = Bytes.
    put-string(Data,1) = Note.
    Socket:write(Data,1,Bytes).
    finally:
        set-size(Data) = 0.
    end finally.
end.

Socket:disconnect().
delete object Socket.

procedure Connect:
    define input  paramete  Port as integer      no-undo.
    define output parameter Socket as handle      no-undo.
    create socket Socket.
    Socket:set-read-response-procedure("Response").
    Socket:connect(substitute("-S &1",Port)).
end procedure.

procedure Response:
    var int Bytes.
    var memptr Data.
    var char Response, Note.

    if not self:connected() 
    then do:
        delete object self.
        return.
    end.
    
    Bytes = self:get-bytes-available().
    set-size(Data) = Bytes.
    self:read(Data,1,Bytes).
    Response = get-string(Data,1).
    Info = substitute("response: &1",Response).
    display Info with frame F.
    
    case Response:
        when "allowed to eat" 
        then do:
            Eat += 1.
            Info = substitute("&1 eating meal &2",Philosophor,Eat).
            display Info with frame F.
            pause 2 no-message.
            Note = "meal finished".
            Info = Note.
            display Info with frame F.
            Bytes = length(Note) + 1.
            set-size(Data) = 0.
            set-size(Data) = Bytes.
            put-string(Data,1) = Note.
            Socket:write(Data,1,Bytes).
            /*
            pause 1 no-message.
            Note = substitute("Philosophor &1 finished meal &2",Philosophor,Eat).
            Bytes = length(Note) + 1.
            set-size(Data) = 0.
            set-size(Data) = Bytes.
            put-string(Data,1) = Note.
            Socket:write(Data,1,Bytes).
            */
        end.
        otherwise do:
            if Response begins "philosopher" 
            then Philosophor = Response.
        end.
    end case.
    finally:
        set-size(Data) = 0.
    end finally.
end procedure.

