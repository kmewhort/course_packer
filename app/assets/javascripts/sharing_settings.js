function SharingSettings(container){
    var coursePackId = $(container).data('coursepack-id');
    var updateUrl = "/course_packs/" + coursePackId;

    // update the sharing settings when changed
    $(container).find('a').click(function(){
      var button = $(this);

      if(!$(this).hasClass('selected') && ($(this).find('.selection.disabled').length == 0)){
          var value =  button.data('share-type');

          // set selection active and reveal share link for "link"
          $(container).find('.selected').removeClass('selected');
          $(this).addClass('selected');
          if(value == 'link')
            $(container).find('.share-link').removeClass('hidden');
          else
            $(container).find('.share-link').addClass('hidden');

          // update the value
          $.ajax({
              url: updateUrl,
              method: 'PUT',
              data: {
                  course_pack: {
                      sharing: value
                  }
              },
              error: function(){
                  alert('Sorry, we encountered an unexpected error saving your sharing selection. Please try again or contact the system administrator.');
              }
          });
      }
    });
}