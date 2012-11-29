$ ->
  window.chart_data = []

  # check user random string exists
  if !user_random_string?
    throw "user random string not found"

  standard_data = () ->
    data = {}
    data['timezone_offset_minutes'] = (new Date()).getTimezoneOffset()
    if window.active_date?
      data['date'] = window.active_date
    data

  alert = (message) ->
    $('#alert').slideUp()
    $('#alert').html('<div class="alert"><a class="close" data-dismiss="alert">×</a><span>'+message+'</span></div>')
    $('#alert').slideDown()
    $('#alert .close').on 'click', (e) ->
      $('#alert').slideUp()

  # returns color between red (p = 0.0) and green (p = 1.0)
  # hsvToRgb(Hue, Sat, Val) defined in color.js
  # used to change hue of score
  calc_color = (p) -> 
    rgb = hsvToRgb(0.33 * p, 1.0, 0.9)
    "rgb(#{Math.floor(rgb[0])}, #{Math.floor(rgb[1])}, #{Math.floor(rgb[2])})"

  change_points = (diff) ->
    for period in ['today', 'this-week', 'this-month', 'all-time']
      points = parseInt $(".score.#{period} h1").text()
      points += diff
      elem = $(".score.#{period} h1").removeClass().addClass("score #{period}")
      # add classes to change font-size based on digits
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
    $(".score.today h1").css("color", "#{calc_color(ratio)}")

  increment_points = () ->
    change_points 1
    update_chart_data 1

  decrement_points = () ->
    change_points -1
    update_chart_data -1

  hover_in = (e) ->
    if $(this).closest('.thing').find('.name').is(':visible')
      $(this).find('.buttons').show()

  hover_out = (e) ->
    $(this).find('.buttons').hide()

  destroy_thing_template = (template_id) ->
    url = "/#{user_random_string}/template/#{template_id}/destroy"
    $.post url, standard_data(), (data, textStatus, jqXHR) ->
      div = $("##{data._id}").parents(".thing")
      div.css('height', div.height())
      div.animate {opacity: 0 },{ duration: 200, complete: () ->
        $(this).slideUp 200, () ->
          $(this).remove()
          set_color()
      }

  set_inactive = (elem, callback = null) ->
    thing_id = $(elem).attr('id')
    url = "/#{user_random_string}/thing/#{thing_id}/destroy"  
    $.post url, standard_data(), (data, textStatus, jqXHR) ->
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
    url = "/#{user_random_string}/thing/#{template_id}/create"
    $.post url, standard_data(), (data, textStatus, jqXHR) ->
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
    # todo: put this in an EJS template
    html = "<div class=\"thing\"><div class=\"icon\"></div><a id=\"#{tt._id}\" class=\"inactive name\">#{tt.name}</a><form class=\"form form-inline\"><input class=\"input-medium\" type=\"text\" value=\"#{tt.name}\"><button class=\"btn\">Submit</button></form><p class=\"buttons\"><a class=\"edit\">edit</a><a class=\"delete\">delete</a></p></div>"
    $(html).appendTo('.things')
    $("##{tt._id}").closest('.thing').find('form').fadeOut(200)
    $("##{tt._id}").closest('.thing').find('.buttons').fadeOut(200)
    $('.add-thing a').click()
    reset_button_functionality()
    set_color()
  
  reset_button_functionality = () ->
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
          url = "/#{user_random_string}/thing/#{id}/edit"
        else
          url = "/#{user_random_string}/template/#{id}/edit"
        data = standard_data()
        data['name'] = value
        data['old_name'] = old_value
        $.post url, data, (ret, textStatus, jqXHR) ->
          $("##{ret._id}").text(ret.name)

      $(this).closest('.thing').find('.name').toggle()
      $(this).closest('.thing').find('form').toggle()
      $(this).closest('.thing').find('.buttons').show()

    $('.add-thing form').unbind()
    $('.add-thing form').submit (e) ->
      e.preventDefault()
      value = $(this).find('input').val()
      if value == ''
        $('.add-thing a').click()
      else if value
        url = "/#{user_random_string}/template/create"
        data = standard_data()
        data['name'] = value
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
      e.preventDefault()
      bookmarkUrl = "http://dayscore.net/#{user_random_string}"
      bookmarkTitle = 'DayScore.net - Reinforce positive habits by keeping score'

      is_chrome = navigator.userAgent.toLowerCase().indexOf('chrome') > -1
      if is_chrome
        alert('Press CTRL-D to bookmark this page.')
        return false

      if (sidebar) 
        sidebar.addPanel(bookmarkTitle, bookmarkUrl,"")
      else if( external || document.all)
        external.AddFavorite( bookmarkUrl, bookmarkTitle)
      else if(opera)
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

  # calculate n-day moving average
  # assumes chart_data is format [[time, value],...]
  # and no days missing or doubled
  calc_ma = (n) ->
    if window.chart_data.length < n
      return []
    # calculate first point
    # y value
    val = window.chart_data[0...n].
      map((x) -> parseFloat(x[1])).
      reduce((x,y) -> x + y) / n
    # if n is even, interpolate to get median x value
    if n % 2 == 0
      time = (window.chart_data[Math.floor(n/2)-1][0] + window.chart_data[Math.floor(n/2)][0]) / 2
    else
      time = window.chart_data[Math.floor(n/2)][0]

    mov_average = [[time, val]]

    # calculate rest
    # uses fact that moving average at x+1 is
    # M(x+1) = M(x) - (D(b) - D(a)) / n
    # where D(x) is the data series, a is the point being removed from the moving average,
    # and b is the point being added to the moving average
    for point in window.chart_data[n..window.chart_data.length]
      # update y values
      new_val = parseFloat(point[1])
      old_val = window.chart_data[mov_average.length - 1][1]
      # add a day
      time += 24*60*60*1000
      # update moving average
      mov_average.push([time, mov_average[mov_average.length - 1][1] + (new_val - old_val) / n])

    mov_average

  # draw chart, uses jquery.flot.js
  draw_chart = () ->
    sma_seven = calc_ma(7)
    sma_thirty = calc_ma(30)
    if window.chart_data.length < 1
      # don't draw empty chart
      return 
    point_options = {}
    if window.chart_data.length == 1
      # if only one point, draw spot
      point_options = { show: true, radius: 5, fill: true, fillColor: '#ACDBF5' }

    daily_score = {}
    daily_score.label =  'daily score'
    daily_score.data =  window.chart_data
    daily_score.color = '#ACDBF5'
    daily_score.lines = {lineWidth: 5, show: true}
    daily_score.points = point_options

    seven_day_ma = {}
    seven_day_ma.label = '7 day moving average'
    seven_day_ma.data = sma_seven
    seven_day_ma.color = '#2FA4E7'
    seven_day_ma.lines = {lineWidth: 5 }

    thirty_day_ma = {}
    thirty_day_ma.label = '30 day moving average'
    thirty_day_ma.data = sma_thirty
    thirty_day_ma.color = '#317EAC'
    thirty_day_ma.lines = {lineWidth: 5 }

    data = [daily_score, seven_day_ma, thirty_day_ma]

    xaxis = {}
    xaxis.mode = 'time'
    xaxis.min = window.chart_data[0][0] - 12*60*60*1000
    xaxis.max = window.chart_data[window.chart_data.length-1][0] + 12*60*60*1000
    xaxis.minTickSize = [1, "day"] 

    yaxis = {}
    yaxis.min = 0
    yaxis.tickSize = 1

    grid = {}
    grid.show = true
    grid.aboveData = true
    grid.borderColor = '#555'

    options = {xaxis: xaxis, yaxis: yaxis, grid: grid}

    chart = $.plot($("#chart"), data, options)
      
    chart.draw()

  # updates score for today by val, 
  # then recalculates moving averages, and draws chart
  update_chart_data = (val) ->
    if window.active_date?
      date = Date.parse(window.active_date) + (new Date()).getTimezoneOffset()*60*1000
      # cycle through chart data until dat matches
      for row in window.chart_data
        if row[0] >= date
          chart_data_row = row
          break
      if chart_data_row
        chart_data_row[1] += val
    else
      window.chart_data[window.chart_data.length-1][1] += val

    sma_seven = calc_ma(7)
    sma_thirty = calc_ma(30)
    draw_chart()

  # process data to add missing days
  process_chart_data = () ->
    if !window.chart_data_hash? || window.chart_data_hash.length < 1
      throw "INVALID CHART DATA HASH"
    start_date = (new Date()).getTime() + 24*2*60*60*1000
    end_date = 0
    # find range
    for k, v of window.chart_data_hash
      if k < start_date
        start_date = k
      if k > end_date
        end_date = k
    window.chart_data = []
    # loop through date range, filling in blanks
    date = parseInt start_date
    while date <= parseInt end_date
      if window.chart_data_hash[date]?
        window.chart_data.push [date, window.chart_data_hash[date]]
      else
        window.chart_data.push [date, 0]
      date += 24*60*60*1000

  # hide forms
  $('.thing form').hide()
  $('.add-thing form').hide()
  $('.thing .buttons').hide()

  set_color()
  reset_button_functionality()
  process_chart_data()
  draw_chart()

  # initialise email
  $('.toggle-email').on 'click', (e) ->
    $('.email-wrap').slideToggle()
  $('form.email').on 'submit', (e) ->
    e.preventDefault()
    email = $(this).find('input').val()
    if email == ''
      alert('Email removed. You will no longer recieve emails from dayscore.net')
    else
      alert('Email added successfully. You will now recieve daily emails showing yesterday\'s progress and your latest stats. Simply remove your email to unsubscribe. Your email address will never be used for any other purposes or shared with third parties.')


    console.log "SUBMIT"

  # initialise datepicker
  today = new Date()
  today_str = "#{today.getFullYear()}/#{today.getMonth()+1}/#{today.getDate()}" 
  $('.datepicker').datepicker(
    'format':'yyyy/mm/dd', 
    'weekStart':1, 
    'autoclose':true, 
    'startDate':'2012/08/01',
    'endDate':today_str).on 'changeDate', (e) -> 
      date = $('.datepicker').val().replace /\//g, '-'
      # redirect to correct date
      window.location.href = "/#{user_random_string}/date/#{date}"

  $('.toggle-datepicker').on 'click', (e) ->
    e.preventDefault()
    $('.datepicker-wrap').slideToggle()
  