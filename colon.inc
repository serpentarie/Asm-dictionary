%define last 0

%macro colon 2
  %ifstr %1
    %ifid %2
      %2:
        dq last
        db %1,0
        %define last %2
      %else
          %error "Второе значение должно быть идентификатором"
      %endif
  %else
      %error "Первое значение должно быть строкой"
  %endif
%endmacro
