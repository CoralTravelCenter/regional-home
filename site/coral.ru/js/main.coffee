import { fixLayout, autoplayVimeo, ASAP, preload } from '/site/common/js/utils.coffee'
import { $fetchAndBuildAvailableDestinations, selectDestinationTab } from './burning-tours.coffee'

Number::formatPrice = () ->
    s = String(Math.round(this))
    s.split('').reverse().join('').replace(/\d{3}/g, "$& ").split('').reverse().join('').replace(/^\s+/, '')


fixLayout()
autoplayVimeo()

doHover = () ->
    $this = $(this)
    idx = $this.index()
    $this.addClass('hovered').siblings('.hovered').removeClass('hovered')
    $('.intro .visual').eq(idx).addClass('shown').siblings().removeClass('shown')

ASAP ->
    do ->
        do_auto_play = yes
        $navs = $('.intro .eternal-package-search > *')
        intro_autoplay_interval = setInterval =>
            if do_auto_play
                idx = $('.intro .eternal-package-search > .hovered').index()
                idx = 0 if ++idx >= $navs.length
                doHover.apply $navs.eq(idx)
        , 2500
        $(document)
        .on 'mouseenter', '.intro .eternal-package-search > *', (e) =>
            do_auto_play = no
            doHover.apply e.target
        .on 'mouseleave', '.intro .eternal-package-search > *', (e) => do_auto_play = yes

    $flickityReady = $.Deferred()
    preload 'https://cdnjs.cloudflare.com/ajax/libs/flickity/2.3.0/flickity.pkgd.min.js', -> $flickityReady.resolve()

    preload 'https://cdnjs.cloudflare.com/ajax/libs/jquery-scrollTo/2.1.3/jquery.scrollTo.min.js', ->
        $(document).on 'click', '[data-scrollto]', -> $(window).scrollTo $(this).attr('data-scrollto'), 500, offset: -150
        $('.tabs-container .scroll-left').on 'click', ->
            $scroll_this = $('.burning-offers .tabs-selector')
            $scroll_this.scrollTo $scroll_this.children(':first'), 500
        $('.tabs-container .scroll-right').on 'click', ->
            $scroll_this = $('.burning-offers .tabs-selector')
            $scroll_this.scrollTo $scroll_this.children(':last'), 500


    $.when($fetchAndBuildAvailableDestinations(preferred_destination_order)).done (available_destinations) ->
        $tabs_selector = $('.burning-offers .tabs-selector')
        $tabs_container = $tabs_selector.closest('.tabs-container')
        lis_html = available_destinations.map (d) ->
            "<li data-destination-name='#{ d.destination_name }' data-destination-id='#{ d.destination_id }' data-destination-url='#{ d.destination_url }' data-option-id='#{ d.option_id }'>#{ d.destination_name }</li>"
        .join ''
        $tabs_selector.empty().append lis_html

        first_tab_el = $tabs_selector.children(':first').get(0)
        last_tab_el = $tabs_selector.children(':last').get(0)
        io = new IntersectionObserver (entries, observer) ->
            for entry in entries
                if entry.target == first_tab_el
                    $tabs_container.toggleClass 'scrollable-left', not entry.isIntersecting
                else if entry.target == last_tab_el
                    $tabs_container.toggleClass 'scrollable-right', not entry.isIntersecting
        , threshold: 0.5, root: $tabs_container.get(0)
        io.observe first_tab_el
        io.observe last_tab_el

        selectDestinationTab '.burning-offers [data-destination-name]:first', $flickityReady

        $(document).on 'click', '.burning-offers [data-destination-name]', ->
            selectDestinationTab this, $flickityReady
            $('.flickity-enabled').flickity 'resize'

    $.when($flickityReady).done ->
        $('.hot-slider').flickity
            cellSelector: '.hot-slide'
            cellAlign: 'center'
            wrapAround: yes
            prevNextButtons: yes
            pageDots: yes

    $(document).on 'wheel', '.flickity-enabled', _.debounce (e) ->
        e.stopPropagation()
        if e.originalEvent.deltaX > 0
            $(this).flickity('next')
        else if e.originalEvent.deltaX < 0
            $(this).flickity('previous')
    , 40, leading: yes, trailing: no
