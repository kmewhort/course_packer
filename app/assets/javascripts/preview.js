function Preview(container){
    this.container = $(container);
}

Preview.prototype.load = function(pdf_file){
    var embeddedViewer = $("<object>")
        .attr('width', '100%').attr('height', '100%')
        .attr('type', 'application/pdf')
        .attr('data', pdf_file)
        .appendTo(this.container.empty());
    $('<embed>')
        .attr('width', '100%').attr('height', '100%')
        .attr('src', pdf_file)
        .attr('type', 'application/pdf')
        .appendTo(embeddedViewer);
}

Preview.prototype.clear = function(){
  this.container.empty();
}
