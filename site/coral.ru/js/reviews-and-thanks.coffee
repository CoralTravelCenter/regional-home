import { ASAP, watchIntersection } from '/site/common/js/utils.coffee'
import { $get } from './local-proxy.coffee'

ASAP ->

    $get('/main/coral/reviewsvotes/').done (reviews_page_html) ->
        domparser = new DOMParser()
        doc = domparser.parseFromString reviews_page_html, 'text/html'
        $all_reviews = $(doc.querySelector('script[type="all/reviews"]').innerHTML).filter '.review-block'
        $('.all-reviews').empty().append $all_reviews.slice 0, 10
        setTimeout ->
            $('.all-reviews').find('.body').each (idx, el) ->
                el.classList.add 'overflown' if el.scrollHeight > el.clientHeight
        , 100
        $(document).on 'click', '.review-block .body.overflown', ->
            $(this).removeClass('overflown').parent().css height: 'auto'

