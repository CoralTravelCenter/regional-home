import { ASAP, watchIntersection } from '/site/common/js/utils.coffee'
import { $get } from './local-proxy.coffee'

ASAP ->
    watchIntersection 'section.reviews-and-thanks', threshold: .1, (observer) ->
        observer.unobserve this
#        $get('/main/coral/reviewsvotes/').done (reviews_page_html) ->
        $get('/otzyv/').done (reviews_page_html) ->
            domparser = new DOMParser()
            doc = domparser.parseFromString reviews_page_html, 'text/html'
            some_frags = doc.querySelector('.otziv-klient-site').innerHTML.split(/<hr[^>]*>/i).slice 0, 10
            structured = some_frags.map (frag) ->
                $frag = $('<div/>').html(frag)
                $body = $frag.find('p > strong').parent().next()
                review =
                    h4: $frag.find('p > strong').text()
                    body: $body.is('p') and $body.html() or $body[0].outerHTML
                    author: $frag.find('p > em').text()
                    date: $frag.find('span').filter((idx,span) -> $(span).css('float') == 'right').text()
            htmls = structured.map (d) -> "<div class=\"review-block\"><div class=\"head-body\"><h4>#{ d.h4 }</h4><div class=\"body\">#{ d.body }</div></div><div class=\"foot\"><div class=\"author\">#{ d.author }</div><div class=\"date\">#{ d.date }</div></div></div>"
            $('.all-reviews').empty().append htmls.join('')
            setTimeout ->
                $('.all-reviews').find('.body').each (idx, el) ->
                    el.classList.add 'overflown' if el.scrollHeight > el.clientHeight
            , 100
            $(document).on 'click', '.review-block .body.overflown', ->
                $(this).removeClass('overflown').parent().css height: 'auto'

            $rw = $('.all-reviews')
            watchIntersection '.all-reviews > *:first-child', root: $rw.get(0),
                (observer) -> $(observer.root).parent().removeClass 'scrollable-left'
                (observer) -> $(observer.root).parent().addClass 'scrollable-left'
            watchIntersection '.all-reviews > *:last-child', root: $rw.get(0),
                (observer) -> $(observer.root).parent().removeClass 'scrollable-right'
                (observer) -> $(observer.root).parent().addClass 'scrollable-right'
