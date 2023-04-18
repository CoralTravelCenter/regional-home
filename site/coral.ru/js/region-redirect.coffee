import { ASAP } from '/site/common/js/utils.coffee'
import reference from '../data/reference.yaml'


if location.hostname != 'localhost'
    ASAP ->
        { name: city_name, value: city_eeID } = window.global.getActiveDeparture()
        city = reference.cities.find (c) -> Number(c.eeID) == Number(city_eeID)
        if city?.pathname != location.pathname
            location.href = city.pathname or '/'