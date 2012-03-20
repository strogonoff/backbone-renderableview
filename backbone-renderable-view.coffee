class RenderableView extends Backbone.View
  ### Template function. Should be provided by the subclass. ###
  template: null
  ### Default context helpers. ###
  contextHelpers:
    ###
    Translation function is assumed to be `window.gettext`, otherwise
    dummy function is used (and should be overridden by subclass then).
    ###
    '_':
      if _.isFunction(window.gettext) then window.gettext
      else (string) -> string
    ### Django's `linebreaks` filter emulator ###
    linebreaks: (string) ->
      value = string.replace /\r\n|\n|\r/g, '\n'
      paras = value.split /\n{2,}/
      paragraphs = []
      for p in paras
        paragraphs.push "<p>#{p.replace(/\n/g, '<br />')}</p>"
      return paragraphs.join "\n\n"

  ###
  Returns a promise to render the template and fill the element with
  resulting HTML.
  Waits for template context and pre_render hooks, if they return
  promises.
  `opts` dictionary is passed from hook to hook and should be returned
  from each of them.
  ###
  render: (opts) =>
    if not @template? then console.error "No template specified for the view!"
    $.Deferred((dfd) =>
      $.when(@_pre_render(opts)).done((opts) =>
        $.when(@_render_template(opts)).then((opts) =>
          $.when(@_post_render(opts)).then((opts) ->
            dfd.resolve()
          ).fail( =>
            console.error "Failed to run post-render hanlder."
          )
        ).fail( =>
          console.error "Failed to render the view."
        )
      ).fail( =>
        console.error "Failed to preload context for the view."
      )
    ).promise()

  _render_template: (opts) ->
    $.Deferred((dfd) =>
      # Defer rendering of template and filling the HTML to `render_template` method.
      @render_template(dfd, opts)
    ).promise()
  _pre_render: (opts) ->
    #console.log "Running pre-render handler"
    $.Deferred((dfd) =>
      # Defer resolving of the promise to `pre_render` method.
      @pre_render(dfd, opts)
    ).promise()
  _post_render: (opts) ->
    #console.log "Running post-render handler"
    $.Deferred((dfd) =>
      # Defer resolving of the promise to `post_render` method.
      @post_render(dfd, opts)
    ).promise()

  ###
  Overridable functions
  Must resolve passed jQuery.Deferred objects when done.
  ###
  render_template: (dfd, opts) ->
    $@el.html @template(@get_template_context(opts))
    #console.log "View render %o - %o", $(@el)?.attr('class'), @model
    dfd.resolve(opts)

  ###
  Override this to pre-load data before rendering the template
  (it may be data required for the context, for example).
  Template rendering will wait until the deferred is resolved.
  ###
  pre_render: (deferred, opts) -> deferred.resolve(opts)

  ###
  Override this to manipulate rendered template. View will not be
  considered as rendered until it's finished.
  ###
  post_render: (deferred, opts) -> deferred.resolve(opts)

  ###
  Collect template context: helpers and data.
  ###
  get_template_context: (opts) ->
    _.extend {}, @contextHelpers,
      @get_context_helpers(opts),
      @get_context_data(opts)

  get_context_helpers: (opts) -> {}
  get_context_data: (opts) -> {}

Backbone.RenderableView = RenderableView
