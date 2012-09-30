$ ->
  # check user random string exists
  if window.user_random_string?
    console.log "user random string: #{window.user_random_string}"
  else
    throw "user random string not found"

  change_points = (diff) ->
    for period in ['today', 'this-week', 'this-month', 'all-time']
      points = parseInt $(".score.#{period} h1").text()
      points += diff
      $(".score.#{period} h1").text(points)

  increment_points = () ->
    change_points 1
    

  decrement_points = () ->
    change_points -1

  # set functionality for buttons to show
  $('.thing .buttons').hide()

  hover_in = (e) ->
    $(this).find('.buttons').toggle()

  hover_out = (e) ->
    $(this).find('.buttons').toggle()

  $('.thing').hover hover_in, hover_out

  destroy_thing_template = (template_id) ->
    url = "#{window.user_random_string}/template/#{template_id}/destroy"
    $.post url, {now: new Date()}, (data, textStatus, jqXHR) ->
      $("##{data._id}").closest('.thing').slideUp("normal", () -> $(this).remove())

  # set button press functionality
  $('.thing .buttons .delete').click (e) ->
    e.preventDefault()

    # if active set inactive to update points and stuff
    if $(this).closest('.thing').find('.name').hasClass('active')
      set_inactive $(this).closest('.thing').find('.name'), destroy_thing_template
    else
      template_id = $(this).closest('.thing').find('.name').attr('id')
      destroy_thing_template(template_id)
        

  set_inactive = (elem, callback = null) ->
    thing_id = $(elem).attr('id')
    console.log "destroy thing id:#{thing_id}"
    url = "#{window.user_random_string}/thing/#{thing_id}/destroy"
    $.post url, {now: new Date()}, (data, textStatus, jqXHR) ->
      template_id = data._id
      # toggle active/inactive
      $("##{thing_id}").removeClass('active')
      $("##{thing_id}").addClass('inactive')
      $("##{thing_id}").parent().find('.icon').html('')
      # set id
      $("##{thing_id}").attr('id', "#{template_id}")
      decrement_points()
      if callback?
        callback(data._id)

  set_active = (elem) ->
    template_id = $(elem).attr('id')
    console.log "add thing template id:#{template_id}"
    url = "#{window.user_random_string}/thing/#{template_id}/create"
    $.post url, {now: new Date()}, (data, textStatus, jqXHR) ->
      thing_id = data._id
      # toggle active/inactive
      $("##{template_id}").addClass('active')
      $("##{template_id}").removeClass('inactive')
      icon = '<i class="icon-ok"></i>'
      $("##{template_id}").parent().find('.icon').html(icon)
      # set id
      $("##{template_id}").attr('id', "#{thing_id}")
      increment_points()

  # set functionality for toggling things
  $('.thing .name').click (e) ->
    e.preventDefault

    # remove thing
    if $(this).hasClass('active')
      set_inactive this

    # add thing
    if $(this).hasClass('inactive')
      set_active this

  # set bookmark on click functionality
  $('.bookmark-link').click (e) ->
    console.log 'click'
    e.preventDefault()
    bookmarkUrl = this.href
    bookmarkTitle = 'DayScore.net - Reinforce positive habits by keeping score'

    is_chrome = navigator.userAgent.toLowerCase().indexOf('chrome') > -1
    if is_chrome
      alert('Press CTRL-D to bookmark this page.')
      return false

    if (window.sidebar) 
      window.sidebar.addPanel(bookmarkTitle, bookmarkUrl,"")
    else if( window.external || document.all)
      window.external.AddFavorite( bookmarkUrl, bookmarkTitle)
    else if(window.opera)
      $("a.jQueryBookmark").attr("href",bookmarkUrl);
      $("a.jQueryBookmark").attr("title",bookmarkTitle);
      $("a.jQueryBookmark").attr("rel","sidebar");
    else
      alert('Your browser does not support this bookmark action')
      return false

  # set change period functionality
  $('.period').click (e) ->
    period = item for item in $(this).attr('class').split(/\s+/g) when item != 'period'
    $('.period').removeClass('active')
    $(".period.#{period}").addClass('active')
    $('.score').hide()
    $(".score.#{period}").show()