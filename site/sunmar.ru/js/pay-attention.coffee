import { ASAP, preload } from '/site/common/js/utils.coffee'

ASAP ->
    $flickityReady = $.Deferred()
    if $.fn.flickity
        $flickityReady.resolve()
    else
        preload 'https://cdnjs.cloudflare.com/ajax/libs/flickity/2.3.0/flickity.pkgd.min.js', -> $flickityReady.resolve()

    $.when($flickityReady).done ->
        $('.pay-attention .banners-grid').flickity
            watchCSS: yes
            cellSelector: '.banner-cell'
            wrapAround: no
            adaptiveHeight: yes
            prevNextButtons: yes
            pageDots: yes