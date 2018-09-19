window.templates_image_templates_index = function(){
  $(document).on("change", "#svg_file_field", function(e){
    var reader = new FileReader();
    var svg_file = document.getElementById('svg_file_field').files[0];
    var svg_preview = document.getElementById('svg_preview');

    if(svg_file){
      reader.readAsDataURL(svg_file);
    }else{
      svg_preview.src = "";
    }

    reader.onloadend = function(){
      svg_preview.src = reader.result;
    }
  });

  $(document).on("change", "#sample_file_field", function(event){
    var sample_reader = new FileReader();
    var sample_file = document.getElementById('sample_file_field').files[0];
    var sample_preview = document.getElementById('sample_preview');

    sample_reader.onloadend = function(){
      sample_preview.src = sample_reader.result;
    }

    if(sample_file){
      sample_reader.readAsDataURL(sample_file);
    }else{
      sample_preview.src = "";
    }
  });

  $(window).on('hide.bs.modal', function(){
    $('.livepreview').livePreview({
      position: 'left'
    });
  });

  $('.livepreview').livePreview({
    position: 'left'
  });

}
