import { Flipdown } from "./Flipdown.coffee"
import { ASAP } from '/site/common/js/utils.coffee'

ASAP ->
    $('.countdown-widget')
    .on 'time-is-up', ->
        $(this).closest('.widgetcontainer').slideUp()
    .Flipdown
        momentX: moment('2023-07-15T20:59:59Z')
    .Flipdown 'start'
