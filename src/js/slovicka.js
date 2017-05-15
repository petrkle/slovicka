var classname = document.getElementsByClassName("slovicko");

var myFunction = function() {
    var attribute = this.getAttribute("data-en");
    alert(attribute);
};

for (var i = 0; i < classname.length; i++) {
    classname[i].addEventListener('click', myFunction, false);
}
