export class AppState {
    _state = {};
    constructor(state_data) {
        if (state_data) {
            if (typeof state_data === 'string') {
                this._state = JSON.parse(state_data);
            } else {
                this._state = JSON.parse(JSON.stringify(state_data));
            }
        }
    }

    get state() {
        return this._state;
    }

    set state(data) {
        this._state = JSON.parse(JSON.stringify(state_data));
        $(this).trigger('changed');
    }

    setPropertyPath(prop_path, value) {
        const props = (prop_path || '').split('.');
        let hasBeenChanged = false;
        if (props.length) {
            let ref = this._state;
            let prop2set = props.pop();
            props.forEach((p, idx) => {
                if (!ref.hasOwnProperty(p)) {
                    ref[p] = {};
                    hasBeenChanged = true;
                }
                ref = ref[p];
            });
            if (ref[prop2set] !== value) {
                hasBeenChanged = true;
            }
            ref[prop2set] = value;
        }
        return hasBeenChanged;
    }

    set(property_path_or_object, value) {
        let hasBeenChanged = false;
        let changes_list = []
        if (typeof property_path_or_object === 'string') {
            hasBeenChanged = this.setPropertyPath(property_path_or_object, value);
            hasBeenChanged && changes_list.push(property_path_or_object);
        } else {
            for (let prop_path in property_path_or_object) {
                let justChanged = this.setPropertyPath(prop_path, property_path_or_object[prop_path]);
                justChanged && changes_list.push(prop_path);
                hasBeenChanged = justChanged || hasBeenChanged;
            }
        }
        hasBeenChanged && $(this).trigger('changed', changes_list);
        return hasBeenChanged;
    }

    get(prop_path) {
        const props = (prop_path || '').split('.');
        if (props.length) {
            let ref = this._state;
            let prop2get = props.pop();
            props.forEach((p) => {
                if (ref.hasOwnProperty(p)) {
                    ref = ref[p];
                } else {
                    return undefined;
                }
            });
            return ref[prop2get];
        }
    }

}

