import { ASAP, watchIntersection } from '/site/common/js/utils.coffee'

ASAP ->

    $list = $('.list-marque ul').addClass('run')
    watchIntersection '.list-marque ul > li', threshold: .33, root: $list.parent().get(0),
        ->
            $(this).addClass 'in-view'
        , (observer) ->
            $this = $(this)
            if $this.hasClass 'in-view'
                setTimeout =>
                    observer.observe $(this).clone().appendTo($this.parent()).get(0)
                , 500
            $this.removeClass 'in-view'
