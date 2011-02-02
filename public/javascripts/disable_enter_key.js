function disableEnterKey(e)
{
  var evt  = (evt) ? evt : ((event) ? event : null);
  var node = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null);
  if ((evt.keyCode == 13) && (node.type=="text")) { 
    alert("กรุณาใช้เม้าส์คลิ้กที่ปุ่มเพื่อดำเนินการต่อ");
    return false;
  }
}

function disableEnterKey_old(e)
{
  var key;
  if(window.event)
    key = window.event.keyCode; //IE
  else
    key = e.which; //firefox
  if(key == 13) {
    alert("กรุณาใช้เม้าส์คลิ้กที่ปุ่มเพื่อดำเนินการต่อ");
    return false; }
  else
    return true;
}