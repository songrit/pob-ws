function disableEnterKey(e)
{
  var key;
  if(window.event)
    key = window.event.keyCode; //IE
  else
    key = e.which; //firefox
  if(key == 13) {
    alert("กรุณาคลิ้กเม้าส์");
    return false; }
  else
    return true;
}