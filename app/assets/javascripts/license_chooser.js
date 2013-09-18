$(document).ready(function(){
    $('.license-chooser').each(function(){
        new LicenseChooser(this);
    });
});

LicenseChooser = function(container){
    var widget = this;
    this.container = $(container);

    // update the form fields whenever the user chooses a different license type or jurisdiction
    this.container.find('.license-type, .license-jurisdiction').change(function(){
        widget.reloadFormInputs();
    });
}

// reload the form fields from the server
LicenseChooser.prototype.reloadFormInputs = function(){
    var article_title = this.container.closest('.article').find('.course_pack_contents_title input');
    var article_index = /(\d+)/.exec(article_title.attr('name'))[1];
    console.log(article_index);

    $.ajax({
        url: '/licenses/edit',
        method: 'GET',
        data: {
          license: {
              id: this.container.attr('id'),
              type: this.container.find('.license-type').val(),
              jurisdiction: this.container.find('.license-jurisdiction').val(),
              version: this.container.find('.license-version').val()
          },
          article_index: article_index
        }
    });
}
