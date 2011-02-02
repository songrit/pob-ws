/* for visorfreemind viewer */
function giveFocus()
{
  document.visorFreeMind.focus();
}
function getMap(map){
  var result=map;
  var loc=document.location+'';
  if(loc.indexOf(".mm")>0 && loc.indexOf("?")>0){
    result=loc.substring(loc.indexOf("?")+1);
  }
  return result;
}
