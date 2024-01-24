import slider_template from 'bundle-text:/site/coral.ru/markup/best-deals-slider-template.html'
import { $get, $post } from './local-proxy.coffee'

LOCAL_CHACHE_BY_DESTINATION = {}

$fetchBestDeals = (params) ->
    $promise = $.Deferred()
    if LOCAL_CHACHE_BY_DESTINATION[params.destinationName]
        $promise.resolve(LOCAL_CHACHE_BY_DESTINATION[params.destinationName])
    else
        request =
            isHomePageRequest: yes
            viewType: 'Box'
        request = Object.assign request, params
        $post '/v1/destination/renderbestdealsbydestination', request
        .done (response) ->
            LOCAL_CHACHE_BY_DESTINATION[params.destinationName] = response
            $promise.resolve(response)
    $promise

$parseResponseMarkup = (markup) ->
    $markup = $(markup).eq(0)
    best_deals_list = $markup.find('a[href^="/hotels/"]').map (idx, a) ->
        $a = $(a)
        $stars = $a.find('.stars')
        price = parseFloat $a.find('.price').text().replace(/[^0-9.,]/g, '').replace(',','.')
        old_price = price * 1.1
        [from, nights, date, tourists] = $a.find('h3 ~ em').text().split(/\s+-\s+/)
        tourists_qty = parseInt tourists
#        tourists = ['','на одного', 'на двоих', 'на троих'][tourists_qty]
        tourists = 'за человека'
        n_stars = $stars.children().length
        stars = new Array(n_stars) if n_stars
        displayed_name = $a.find('h3').html()?.replace(/\s*\(.+/,'')
        if n_stars
            unless displayed_name.indexOf(stars) > 0
                displayed_name += " #{ n_stars }*"
        hotel_info =
            name: displayed_name
            location: $a.find('h3 + p').text().split(/,\s*/).pop().replace(/\s*\(.*/,'')
            category: $stars.children().length or $stars.text()
            stars: stars
            nights: nights
            tourists: tourists
            transfer_info: $a.find('.flight').html()
            visual: $a.find('img[data-src]').attr('data-src')
            price_formatted: (price / tourists_qty).formatPrice()
            old_price_formatted: (old_price / tourists_qty).formatPrice()
            xlink: $a.attr('href')
    .toArray()

export selectDestinationTab = (tab_el, $flickityReady) ->
    $tab_el = $(tab_el)
    existing_slider = $tab_el.addClass('selected').prop 'best-deals-slider'
    $tab2hide = $tab_el.siblings('.selected')
    if $tab2hide.length
        $($tab2hide.prop('best-deals-slider')).addClass('disabled')
        $tab2hide.removeClass('selected')
    if existing_slider
        $(existing_slider).removeClass('disabled').show().siblings('.disabled').hide()
    else
        $fetchBestDeals
            destinationId: $tab_el.attr('data-destination-id')
            destinationName: $tab_el.attr('data-destination-name')
            destinationUrl: $tab_el.attr('data-destination-url')
            optionId: $tab_el.attr('data-option-id')
        .done (best_deals_markup) ->
            best_deals_list = $parseResponseMarkup(best_deals_markup)
            $slider_markup = $ Mustache.render slider_template, best_deals_list: best_deals_list
            $('.burning-offers .destinations-container').append $slider_markup
            $tab_el.prop 'best-deals-slider', $slider_markup.get(0)
            $slider_markup.siblings('.disabled').hide()
            $.when($flickityReady).done ->
                $slider_markup.flickity
                    cellSelector: '.best-deal-card'
                    wrapAround: no
                    groupCells: yes
                    contain: yes
                    prevNextButtons: yes
                    pageDots: yes
                $('.flickity-enabled').flickity 'resize'

export $fetchAndBuildBestDeals = (destination_preferred_order=[], home_tab_name) ->
    $promise = $.Deferred()
    $get('/').done (home_html) ->
        domparser = new DOMParser()
        doc = domparser.parseFromString home_html, 'text/html'
        bestdealsbox = doc.querySelector '[data-module="bestdealsbox"]'
        links = Array.from bestdealsbox.querySelectorAll '.nav-link[data-optionid]'
        if home_tab_name
            uniq_links = links
        else
            uniq_links = links.filter (nav_link) -> !!nav_link.getAttribute 'data-optionid'
        uniq_links = _.uniqBy uniq_links, (nav_link) -> nav_link.getAttribute 'data-optionid'
        available_destinations = uniq_links.map (nav_link) ->
            destination_name = nav_link.getAttribute 'data-name'
            destination_name = home_tab_name if destination_name == 'Все'
            data =
                destination_name: destination_name
                destination_id: nav_link.getAttribute 'data-id'
                destination_url: nav_link.getAttribute 'data-url'
                option_id: nav_link.getAttribute('data-optionid') or bestdealsbox.getAttribute('data-option-id')
        .sort (a,b) ->
            aidx = destination_preferred_order.indexOf a.destination_name
            aidx = Infinity if aidx < 0
            bidx = destination_preferred_order.indexOf b.destination_name
            bidx = Infinity if bidx < 0
            if aidx < bidx then -1 else if aidx > bidx then 1 else 0
        console.log('+++ available_destinations: %o', available_destinations)
        $promise.resolve available_destinations
    $promise
