$ ->
  # check user random string exists
  if window.user_random_string?
    console.log "user random string: #{window.user_random_string}"
  else
    throw "user random string not found"

  # returns color between red (p = 0.0) and green (p = 1.0)
  window.get_color = (p) -> 
    H = 0.33 * p
    S = 1.0
    V = 0.9
    rgb = hsvToRgb(H, S, V)
    str = "rgb(#{Math.floor(rgb[0])}, #{Math.floor(rgb[1])}, #{Math.floor(rgb[2])})"
    console.log str
    return str

  change_points = (diff) ->
    for period in ['today', 'this-week', 'this-month', 'all-time']
      points = parseInt $(".score.#{period} h1").text()
      points += diff
      elem = $(".score.#{period} h1").removeClass()
      elem.addClass("score #{period}")
      if points > 1000
        elem.addClass('thousands')
      else if points > 100
        elem.addClass('hundreds')
      else if points > 10
        elem.addClass('tens')
      $(".score.#{period} h1").text(points)
    set_color()

  set_color = () ->    
    points = parseFloat $(".score.today h1").text()
    possible_points = parseFloat $('.thing').length
    ratio = points / possible_points
    # set color for today's score
    $(".score.today h1").css("color", "#{window.get_color(ratio)}")

  increment_points = () ->
    change_points 1
    window.update_chart_data 1
    

  decrement_points = () ->
    change_points -1
    window.update_chart_data -1


  hover_in = (e) ->
    if $(this).closest('.thing').find('.name').is(':visible')
      $(this).find('.buttons').show()

  hover_out = (e) ->
    $(this).find('.buttons').hide()

  destroy_thing_template = (template_id) ->
    url = "#{window.user_random_string}/template/#{template_id}/destroy"
    $.post url, {now: new Date()}, (data, textStatus, jqXHR) ->
      $("##{data._id}").closest('.thing').slideUp("normal", () -> $(this).remove(); set_color();)

  set_inactive = (elem, callback = null) ->
    thing_id = $(elem).attr('id')
    console.log "destroy thing id:#{thing_id}"
    url = "#{window.user_random_string}/thing/#{thing_id}/destroy"  
    $.post url, null, (data, textStatus, jqXHR) ->
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
    $.post url, {'now': (new Date()).toJSON()}, (data, textStatus, jqXHR) ->
      thing_id = data._id
      # toggle active/inactive
      $("##{template_id}").addClass('active')
      $("##{template_id}").removeClass('inactive')
      icon = '<i class="icon-ok"></i>'
      $("##{template_id}").parent().find('.icon').html(icon)
      # set id
      $("##{template_id}").attr('id', "#{thing_id}")
      increment_points()

  prepend_thing_template = (tt) ->
    html = "<div class=\"thing\"><div class=\"icon\"></div><a id=\"#{tt._id}\" class=\"inactive name\">#{tt.name}</a><form class=\"form form-inline\"><input class=\"input-medium\" type=\"text\" value=\"#{tt.name}\"><button class=\"btn\">Submit</button></form><p class=\"buttons\"><a class=\"edit\">edit</a><a class=\"delete\">delete</a></p></div>"
    $(html).appendTo('.things')
    $("##{tt._id}").closest('.thing').find('form').hide()
    $("##{tt._id}").closest('.thing').find('.buttons').hide()
    $('.add-thing a').click()
    reset_button_functionality()
    set_color()
  
  reset_button_functionality = () ->
    console.log "RESETING BUTTONS"

    # set functionality for buttons to show
    $('.thing .buttons').hide()
    $('.thing').unbind()
    $('.thing').hover hover_in, hover_out

    # set button press functionality
    $('.thing .buttons .delete').unbind()
    $('.thing .buttons .delete').click (e) ->
      e.preventDefault()

      # if active set inactive to update points and stuff
      if $(this).closest('.thing').find('.name').hasClass('active')
        set_inactive $(this).closest('.thing').find('.name'), destroy_thing_template
      else
        template_id = $(this).closest('.thing').find('.name').attr('id')
        destroy_thing_template(template_id)

    $('.thing .buttons .edit').unbind()
    $('.thing .buttons .edit').click (e) ->
      e.preventDefault()
      $(this).closest('.thing').find('.buttons').toggle()
      $(this).closest('.thing').find('.name').toggle()
      $(this).closest('.thing').find('form').toggle()

    $('.add-thing a').unbind()
    $('.add-thing a').click (e) ->
      e.preventDefault()
      $('.add-thing form').toggle()
      $('.add-thing a').toggle()

    $('.thing form').unbind()
    $('.thing form').submit (e) ->
      e.preventDefault()
      value = $(this).find('input').val()
      old_value = $(this).closest('.thing').find('.name').text()
      if value and value != '' and value != old_value
        id = $(this).closest('.thing').find('.name').attr('id')
        if $("##{id}").hasClass('active')
          url = "#{window.user_random_string}/thing/#{id}/edit"
        else
          url = "#{window.user_random_string}/template/#{id}/edit"
        data = {name: value, old_name: old_value}
        $.post url, data, (ret, textStatus, jqXHR) ->
          $("##{ret._id}").text(ret.name)

      $(this).closest('.thing').find('.name').toggle()
      $(this).closest('.thing').find('form').toggle()
      $(this).closest('.thing').find('.buttons').show()

    $('.add-thing form').unbind()
    $('.add-thing form').submit (e) ->
      e.preventDefault()
      value = $(this).find('input').val()
      if value and value != ''
        url = "#{window.user_random_string}/template/create"
        data = {name: value}
        $.post url, data, (ret, textStatus, jqXHR) ->
          prepend_thing_template ret

    # set functionality for toggling things
    $('.thing .name').unbind()
    $('.thing .name').click (e) ->
      e.preventDefault()

      # remove thing
      if $(this).hasClass('active')
        set_inactive this

      # add thing
      if $(this).hasClass('inactive')
        set_active this

    # set bookmark on click functionality
    $('.bookmark-link').unbind()
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
    $('.period').unbind()
    $('.period').click (e) ->
      if $(this).hasClass('active')
        return
      period = item for item in $(this).attr('class').split(/\s+/g) when item != 'period'
      $('.period').removeClass('active')
      $(".period.#{period}").addClass('active')
      $('.score').hide()
      $(".score.#{period}").show()

  # calculate seven day moving average
  window.calc_sma = (n) ->
    if window.chart_data.length < n
      return []
    # calculate first point
    sum_n = window.chart_data[0...n].map((x) -> parseFloat(x[1]))
    sum_time = window.chart_data[0...n].map((x) -> parseFloat(x[0]))
    mov_average = []
    mov_average.push [(sum_time.reduce (x,y) -> x + y) / n, (sum_n.reduce (x,y) -> x + y) / n]
    # calculate middle points
    for point in window.chart_data[n..window.chart_data.length]
      val = parseFloat(point[1])
      time = point[0]
      sum_n.shift()
      sum_n.push(val)
      sum_time.shift()
      sum_time.push(time)
      mov_average.push([(sum_time.reduce (x,y) -> x + y) / n, (sum_n.reduce (x,y) -> x + y) / n])
    # calculate last point
    sum_n = window.chart_data[(window.chart_data.length-n)...window.chart_data.length].map((x) -> parseFloat(x[1]))
    sum_time = window.chart_data[(window.chart_data.length-n)...window.chart_data.length].map((x) -> parseFloat(x[0]))
    #mov_average.push [(sum_time.reduce (x,y) -> x + y) / n, (sum_n.reduce (x,y) -> x + y) / n]
    mov_average

  # draw chart
  window.draw_chart = (slide = false) ->
    window.sma_seven = window.calc_sma(7)
    window.sma_thirty = window.calc_sma(30)
    if window.chart_data.length < 1
      return
    point_options = {}
    if window.chart_data.length < 2
      point_options = { show: true, radius: 5, fill: true, fillColor: '#ACDBF5' }
    if (slide == true)
      console.log 'slide'
    chart = $.plot($("#chart"), [ 
      {label: 'daily score', data: window.chart_data, color: '#ACDBF5', lines: {lineWidth: 5, show: true}, points: point_options }, # 2FA4E7
      {label: '7 day moving average', data: window.sma_seven, color: '#2FA4E7', lines: {lineWidth: 5 }},
      {label: '30 day moving average', data: window.sma_thirty, color: '#317EAC', lines: {lineWidth: 5}}  ], 
      { xaxis: { mode: 'time', min: window.chart_data[0][0] - 12*60*60*1000, max: window.chart_data[window.chart_data.length-1][0] + 12*60*60*1000, minTickSize: 24*60*60*1000 }, yaxis: { min: 0, tickSize: 1 }})
    chart.draw()

  # updates todays chart data by +- 1
  window.update_chart_data = (val) ->
    today = (new Date())
    today.setHours(0,0,0,0)
    today = today.getTime()
    if val == -1
      window.chart_data[window.chart_data.length-1][1] -= 1
    else if val == 1
      window.chart_data[window.chart_data.length-1][1] += 1

    window.sma_seven = window.calc_sma(7)
    window.sma_thirty = window.calc_sma(30)
    window.draw_chart()

  # process data to add missing days
  window.process_chart_data = () ->
    if chart_data_hash.length < 1
      throw "NO CHART DATA HASH"
    start_date = (new Date()).getTime() + 24*2*60*60*1000
    end_date = 0
    for k, v of chart_data_hash
      if k < start_date
        start_date = k
      if k > end_date
        end_date = k
    window.chart_data = []
    start_date = parseInt start_date
    end_date = parseInt end_date
    date = start_date
    while date <= end_date
      if chart_data_hash[date]?
        window.chart_data.push [date, chart_data_hash[date]]
      else
        window.chart_data.push [date, 0]
      date += 24*60*60*1000

  # hide forms
  $('.thing form').hide()
  $('.add-thing form').hide()
  $('.thing .buttons').hide()
  set_color()
  window.process_chart_data()
  window.draw_chart()
  reset_button_functionality()
  