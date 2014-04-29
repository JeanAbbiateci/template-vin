# Encoding: utf-8
# -----------------------------------------------------------------------------
# Project : Dragons Gifts
# -----------------------------------------------------------------------------
# Author : Edouard Richard                                  <edou4rd@gmail.com>
# -----------------------------------------------------------------------------
# License : GNU Lesser General Public License
# -----------------------------------------------------------------------------
# Creation : 16-Jan-2014
# Last mod : 04-Feb-2014
# -----------------------------------------------------------------------------
#
#    AFRICA MAP
#
# -----------------------------------------------------------------------------
class AfricaMap

  CONFIG =
    close_zoom                 : 3
    radius_circle_tour         : 6
    scale_range_overview       : [4, 15] # scale to compute the circle radius
    transition_map_duration    : 1000
    transition_circle_duration : 500
    transition_circle_ease     : "easeInSine"

  constructor: (navigation, countries, projects, overview) ->
    @navigation   = navigation
    @countries    = countries
    @projects     = projects
    @overview     = overview
    @current_mode = undefined
    
    # Create svg tag
    @svg = d3.select(".africa-container")
      .insert("svg", ":first-child")

    @group = @svg.append("g")
    # Create the group of path
    @groupPaths = @group.append("g")
      .attr("class", "all-path")
    @groupOverview = @group.append("g")
      .attr("class", "all-overview-points")
    @groupProject = @group.append("g")
      .attr("class", "all-project-points")

    @relayout()

    # Bind events
    $(document).on "modeChanged"     , @onModeChanged
    $(document).on "projectSelected" , @onProjectSelected
    $(document).on "overviewSelected", @onOverviewSelected
    $(window)  .resize                 @relayout

  relayout: =>
    @width = $(".africa-container").width()
    @height = @width * 1
    if @height > $(window).height()
       @height = $(window).height()
       @width = @height / 1
    @svg = d3.select(".africa-container svg")
      .attr("width", @width * 2)
      .attr("height", $(window).height())

    # Create projection
    @projection = d3.geo.mercator()
      .scale(5500) # ... depends of the projection I think. Try!
      .translate([@width/2 - 780, @height/2 + 5150])

    # Create the Africa path
    @path = d3.geo.path()
      .projection(@projection)

     # Create every countries
    @groupPaths.selectAll("path").remove()
    @groupPaths.selectAll("path")
      .data(@countries)
      .enter()
        .append("path")
        .attr("d", @path)

    if @current_mode == "overview"
      @drawOverviewCircles()
    else
      @drawProjectCircles()

  drawCircles: (scale_or_radius, radius_field_name="usd_defl", appearing_animatation=true) =>
    that = this

    get_radius = (d) ->
      ### return the radius, depending of the type of scale_or_radius ###
      if typeof(scale_or_radius) == "number"
        scale_or_radius
      else
        scale_or_radius(parseFloat(d[radius_field_name]))

    @circles.each (d) ->
      d3.select(this)
        .attr("cx", (d) -> that.projection([d.lon, d.lat])[0])
        .attr("cy", (d) -> that.projection([d.lon, d.lat])[1])
      if appearing_animatation
        d3.select(this)
          .attr("r" , 0) # init rayon before transition
          .transition()
            .ease(CONFIG.transition_circle_ease)
            .duration(CONFIG.transition_circle_duration)
            .delay(CONFIG.transition_map_duration)
              .attr("r" , get_radius)
      else
       d3.select(this)
        .attr("r", get_radius)

  drawProjectCircles: =>
    that = this
    #remove previous circles
    @groupOverview.selectAll("circle").transition()
      .ease(CONFIG.transition_circle_ease)
      .duration(CONFIG.transition_circle_duration)
      .attr("r", 0).remove()
    # create circles
    @circles = @groupProject.selectAll("circle")
      .data(@projects)
    @circles.enter()
      .append("circle")
        .on 'click', (d) ->
          that.navigation.setProject(d)
    # postioning cirlces
    @drawCircles(CONFIG.radius_circle_tour)
    # tooltip
    @circles.each (d) ->
      $(d3.select(this)).qtip
        content: "#{d.title}<br/>#{d.recipient_oecd_name}"
        style  : 'qtip-dark'

  onProjectSelected: (e, project) =>
    # select a cirlce
    @circles.each (d, i) -> d3.select(this).classed("active", project is d)
    # zoom
    selected = @circles.filter((d) -> d is project)
    if project? # zoom
      offset_x = - (parseFloat(selected.attr("cx")) * CONFIG.close_zoom - @width / 2)
      offset_y = - (parseFloat(selected.attr("cy")) * CONFIG.close_zoom - @height / 2)
      @group.selectAll("path, circle")
        .transition()
        .duration(CONFIG.transition_map_duration)
        .attr "transform", "translate(#{offset_x}, #{offset_y})scale(#{CONFIG.close_zoom})"
    else # dezoom
      @group.selectAll("path, circle")
        .transition()
          .duration(CONFIG.transition_map_duration)
          .delay(CONFIG.transition_circle_duration)
          .attr "transform", "translate(0,0)scale(1)"

  onOverviewSelected: (e, country) =>
    ### color the circle on the map ###
    @circles.each (d, i) -> d3.select(this).classed("active", country is d)

  drawOverviewCircles: =>
    that = this
    # compute scale
    values = @overview.map((d) -> parseFloat(d.USD))
    scale  = d3.scale.linear()
      .domain([Math.min.apply(Math, values), Math.max.apply(Math, values)])
      .range(CONFIG.scale_range_overview)
    #remove previous circles
    @groupProject.selectAll("circle").transition()
      .ease(CONFIG.transition_circle_ease)
      .duration(CONFIG.transition_circle_duration)
      .attr("r", 0).remove()
    @circles = @groupOverview.selectAll("circle")
      .data(@overview)
    @circles.enter()
      .append("circle")
        .on 'click', (d) ->
          that.navigation.setOverview(d)
    @drawCircles(scale, "USD")
    # tooltip
    @circles.each (d) ->
      $(d3.select(this)).qtip
        content: "#{d.Country}"
        style  : 'qtip-dark'

  onModeChanged: (e, mode) =>
    if (mode == MODE_OVERVIEW or mode == MODE_OVERVIEW_INTRO)
      if @current_mode != "overview"
        @current_mode = "overview"
        @drawOverviewCircles()
    else if @current_mode != "project"
      @current_mode = "project"
      @drawProjectCircles()

# EOF
