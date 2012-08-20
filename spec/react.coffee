###
Use the React library to hook into data events.
###
describe 'react', ->

    it 'hooks into properties before they are set', ->
        check = null
        x =
            a: 'Hello'
        $(x).react 'before', (object, property, value) ->
            check =
                object: object
                property: property
                value: value
        x.a = 'Hello World'
        expect(check).toEqual
            object: x
            property: 'a'
            value: 'Hello'

    it 'hooks into properties after they are set', ->
        check = null
        x =
            a: 'Hello'
        $(x).react 'after', (object, property, value) ->
            check =
                object: object
                property: property
                value: value
        x.a = 'Hello World'
        expect(check).toEqual
            object: x
            property: 'a'
            value: 'Hello World'

    it 'can be turned off', ->
        check = []
        x =
            a: 'Hello'
        $(x).react 'before after', (object, property, value) ->
            check.push
                object: object
                property: property
                value: value
        $(x).react 'off'
        x.a = 'Hello World'
        expect(check).toEqual []

#can I hook a proxy to window and get all data?
