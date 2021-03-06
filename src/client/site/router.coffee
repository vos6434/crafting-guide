#
# Crafting Guide - router.coffee
#
# Copyright © 2014-2017 by Redwood Labs
# All rights reserved.
#

BrowsePageController   = require "./browse_page/browse_page_controller"
CraftPageController    = require "./craft_page/craft_page_controller"
ItemPage               = require "../models/site/item_page"
ItemPageController     = require "./item_page/item_page_controller"
{ItemSlug}             = require("crafting-guide-common").deprecated.game
LoginPageController    = require "./login_page/login_page_controller"
ModPageController      = require "./mod_page/mod_page_controller"
NewsPageController     = require "./news_page/news_page_controller"
TutorialPageController = require "./tutorial_page/tutorial_page_controller"
UrlParams              = require "./url_params"

########################################################################################################################

module.exports = class Router extends Backbone.Router

    constructor: (siteController, options={})->
        if not siteController? then throw new Error "siteController is required"

        @_siteController = siteController
        @_lastReported = null

        super options

    # Backbone.Router Overrides ####################################################################

    navigate: ->
        super
        tracker.trackPageView()

    routes:
        '':                                                     'route__home'
        '/':                                                    'route__home'
        '/index.html':                                          'route__home'

        'browse':                                               'route__browse'
        'browse/':                                              'route__browse'
        'browse/index.html':                                    'route__browse'

        'browse/:modId':                                        'route__browseMod'
        'browse/:modId/':                                       'route__browseMod'
        'browse/:modId/index.html':                             'route__browseMod'

        'browse/:modId/:itemSlug':                              'route__browseModItem'
        'browse/:modId/:itemSlug/':                             'route__browseModItem'
        'browse/:modId/:itemSlug/index.html':                   'route__browseModItem'

        'browse/:modId/tutorials/:tutorialSlug':                'route__browseTutorial'
        'browse/:modId/tutorials/:tutorialSlug/':               'route__browseTutorial'
        'browse/:modId/tutorials/:tutorialSlug/index.html':     'route__browseTutorial'

        'configure':                                            'route__configure'
        'configure/':                                           'route__configure'
        'configure/index.html':                                 'route__configure'

        'craft':                                                'route__craft'
        'craft/':                                               'route__craft'
        'craft/index.html':                                     'route__craft'

        'craft/:text':                                          'route__craft'
        'craft/:text/':                                         'route__craft'
        'craft/:text/index.html':                               'route__craft'

        'login':                                                'route__login'
        'login/':                                               'route__login'
        'login/index.html':                                     'route__login'

        'news':                                                 'route__news'
        'news/':                                                'route__news'
        'news/index.html':                                      'route__news'

        'item/:itemSlug':                                       'deprecated__item'
        'crafting/(:text)':                                     'deprecated__crafting'
        'mod/:modSlug':                                         'deprecated__mod'
        'mod/:modSlug/:itemSlug':                               'deprecated__modItem'

    # Route Methods ################################################################################

    route__home: ->
        params = new UrlParams recipeName:{type:'string'}, count:{type:'integer'}
        if params.recipeName?
            @deprecated__v1_root params
            return

        @route__craft()

    route__browse: ->
        @_siteController.setPage 'browse', new BrowsePageController @_makeOptions {}

    route__browseMod: (modId)->
        controller = new ModPageController @_makeOptions()
        controller.model = @_siteController.modPack.mods[modId]
        @_siteController.setPage 'browseMod', controller

    route__browseModItem: (modId, itemSlug)->
        item = @_siteController.modPack.findItemBySlug itemSlug, modId:modId
        if not item? then throw new Error "could not find item #{modId}__#{itemSlug}"

        itemPage = new ItemPage item
        itemPage.loadDetails()

        params = new UrlParams login:{type:'boolean', default:false}
        controller = new ItemPageController @_makeOptions {model:itemPage, login:params.login}
        @_siteController.setPage 'browseModItem', controller

    route__browseTutorial: (modSlug, tutorialSlug)->
        params = new UrlParams login:{type:'boolean', default:false}
        controller = new TutorialPageController @_makeOptions
            login:params.login, modSlug:modSlug, tutorialSlug:tutorialSlug
        @_siteController.setPage 'browseTutorial', controller

    route__configure: ->
        @route__craft()

    route__craft: (text)->
        controller = new CraftPageController @_makeOptions params:inventoryText:text
        @_siteController.setPage 'craft', controller

    route__login: ->
        params = new UrlParams code:{type:'string'}, state:{type:'string'}
        controller = new LoginPageController @_makeOptions {params:params}
        @_siteController.setPage 'login', controller

    route__news: ->
        controller = new NewsPageController @_makeOptions {}
        @_siteController.setPage 'news', controller

    # Deprecated Route Methods #####################################################################

    deprecated__crafting: (text)->
        controller = new CraftPageController @_makeOptions {}
        controller.model.params = inventoryText:text
        @_siteController.setPage 'crafting', controller

    deprecated__item: (itemSlug)->
        controller = new ItemPageController @_makeOptions {itemSlug:ItemSlug.slugify(itemSlug)}
        @_siteController.setPage 'item', controller

    deprecated__modItem: (modSlug, itemSlug)->
        slug = new ItemSlug modSlug, itemSlug
        controller = new ItemPageController @_makeOptions {itemSlug:slug}
        @_siteController.setPage 'item', controller

    deprecated__mod: (modSlug)->
        controller = new ModPageController  @_makeOptions {}
        controller.model = @_siteController.modPack.getMod modSlug
        @_siteController.setPage 'mod', controller

    deprecated__v1_root: (params)->
        text = ''
        if params.recipeName?
            if params.count? and params.count > 1
                text = "#{params.count}.#{_.slugify(params.recipeName)}"
            else
                text = _.slugify params.recipeName

        @navigate c.url.crafting(inventoryText:text), trigger:true

    # Private Methods ##############################################################################

    _makeOptions: (options={})->
        return _.extend options, @_siteController.controllerOptions
