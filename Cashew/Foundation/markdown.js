//list-style:none;

window.onload = function() {
    var elements = document.getElementsByTagName("li")
    for (var i = 0; i < elements.length; i++) {
        var element = elements[i]
        if (element.firstChild && element.firstChild.type === 'checkbox') {
            element.style.listStyle = "none"
//            element.style.backgroundColor = "red"
//            console.log("element", element)
        }
        // alert(element)
    }
    
    // disable checkbox
    var inputTags = document.getElementsByTagName('input')
    for (var i = 0; i < inputTags.length; i++) {
        var element = inputTags[i]
        if (element.type === 'checkbox') {
            element.disabled = true;
        }
    }

    
    var imageTags = document.getElementsByTagName("img")
    for (var i = 0; i < imageTags.length; i++) {
        var element = imageTags[i];

        element.addEventListener('click', function() {
          //document.body.style.backgroundColor = "red"
          window.Cashew.didClickImage(this.src)
        }, false);
    }
}




