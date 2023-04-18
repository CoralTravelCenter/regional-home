import { ASAP } from '/site/common/js/utils.coffee'
import reference from '../data/reference.yaml'

ASAP ->
    { name: city_name, value: city_eeID } = window.global.getActiveDeparture()
    city = reference.cities.find (c) -> Number(c.eeID) == Number(city_eeID)
    location.href = city.pathname if city?.pathname
    return