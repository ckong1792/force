_ = require 'underscore'
sd = require('sharify').data
CTABarView = require '../../cta_bar/view.coffee'
Backbone = require 'backbone'
analyticsHooks = require '../../../lib/analytics_hooks.coffee'
editorialCTABannerTemplate = -> require('../templates/editorial_cta_banner.jade') arguments...
editorialSignupLushTemplate = -> require('../templates/editorial_signup_lush.jade') arguments...
Cycle = require '../../cycle/index.coffee'
{ crop } = require '../../resizer/index.coffee'
mailcheck = require '../../mailcheck/index.coffee'
mediator = require '../../../lib/mediator.coffee'
FlashMessage = require '../../flash/index.coffee'
qs = require 'querystring'

module.exports = class EditorialSignupView extends Backbone.View

  events: ->
    'click .js-article-es': 'onSubscribe'
    'click .js-article-es-dismiss': 'onDismiss'
    'click .modal-bg': 'hideEditorialCTA'
    'click .cta-bar-defer': 'hideEditorialCTA'

  initialize: ({isArticle = false}) ->
    @setupAEArticlePage() if isArticle
    @setupAEMagazinePage() if @inAEMagazinePage()

  eligibleToSignUp: ->
    @inAEMagazinePage() and
    not sd.SUBSCRIBED_TO_EDITORIAL and
    qs.parse(location.search.replace(/^\?/, '')).utm_source isnt 'sailthru'

  inAEMagazinePage: ->
    sd.CURRENT_PATH is '/articles'

  setupAEMagazinePage: ->
    @ctaBarView = new CTABarView
      name: 'editorial-signup'
      persist: true
    # Show the lush CTA after the 6th article
    @fetchSignupImages (images) =>
      @$('.articles-feed-item').eq(5).after editorialSignupLushTemplate
        email: sd.CURRENT_USER?.email or ''
        images: images
        crop: crop
        isSignup: @eligibleToSignUp()
      mailcheck.run '#articles-es-cta__form-input', '#js--mail-hint', false
      @cycleImages() if images
    if not @ctaBarView.previouslyDismissed() and @eligibleToSignUp()
      @showEditorialCTA()

  setupAEArticlePage: ->
    @ctaBarView = new CTABarView
      mode: 'editorial-signup'
      name: 'editorial-signup-dismissed'
      persist: true
      email: sd.CURRENT_USER?.email or ''
    return if qs.parse(location.search.replace(/^\?/, '')).utm_source is 'sailthru'
    unless @ctaBarView.previouslyDismissed()
      @showEditorialCTA()

  cycleImages: =>
    cycle = new Cycle
      $el: $('.articles-es-cta__background')
      selector: '.articles-es-cta__images'
      speed: 5000
    cycle.start()

  fetchSignupImages: (cb) ->
    $.ajax
      type: 'GET'
      url: "#{sd.POSITRON_URL}/api/curations/#{sd.EMAIL_SIGNUP_IMAGES_ID}"
      success: (results) ->
        cb results.images
      error: ->
        cb null

  showEditorialCTA: ->
    @$('#modal-container').append editorialCTABannerTemplate
      mode: 'modal'
      email: sd.CURRENT_USER?.email or ''
      image: sd.EDITORIAL_CTA_BANNER_IMG
    window.addEventListener 'scroll', () =>
      setTimeout((=> $('.articles-es-cta--banner').css('opacity', 1)), 2000)
    analyticsHooks.trigger('view:editorial-signup', type: 'modal' )

  hideEditorialCTA: (e) ->
    e?.preventDefault()
    cta = @$(e.target).closest('.articles-es-cta--banner')
    @onDismiss(e)
    cta.fadeOut()

  # Subscribe controls
  onSubscribe: (e) ->
    @$(e.currentTarget).addClass 'is-loading'
    @email = @$(e.currentTarget).prev('input').val()
    $.ajax
      type: 'POST'
      url: '/editorial-signup/form'
      data:
        email: @email
        name: sd.CURRENT_USER?.name or= ''
      error: (res) =>
        new FlashMessage message: 'Whoops, there was an error. Please try again.'
        @$(e.currentTarget).removeClass 'is-loading'
      success: (res) =>
        new FlashMessage
          message: 'Thank you for signing up.'
          visibleDuration: 2000
        @$(e.currentTarget).removeClass 'is-loading'
        # Lush Signup
        @$('.articles-es-cta__container').fadeOut =>
          @$('.articles-es-cta__social').fadeIn()
        # Modal Signup
        @$('.articles-es-cta--banner').fadeOut()

        analyticsHooks.trigger('submit:editorial-signup', type: @getSubmissionType(e), email: @email)

  getSubmissionType: (e)->
    type = $(e.currentTarget).data('type')
    if @inAEMagazinePage()
      'magazine_fixed'
    else
      'article_popup'

  onDismiss: (e)->
    @ctaBarView.logDimissal()
    analyticsHooks.trigger('dismiss:editorial-signup', type: @getSubmissionType(e))
