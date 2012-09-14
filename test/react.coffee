###
Use the React library to hook into data events.
###

require '../src/watch'
require '../src/proxy'
require '../src/react'
expect = require 'expect.js'


describe 'react', ->

    it 'hooks into properties before they are set', ->
        check = null
        x =
            a: 'Hello'
        x.react 'before', (object, property, value) ->
            check =
                object: object
                property: property
                value: value
        x.a = 'Hello World'
        expect(check).to.eql
            object: x
            property: 'a'
            value: 'Hello'

    it 'hooks into properties after they are set', ->
        check = null
        x =
            a: 'Hello'
        x.react 'after', (object, property, value) ->
            check =
                object: object
                property: property
                value: value
        x.a = 'Hello World'
        expect(check).to.eql
            object: x
            property: 'a'
            value: 'Hello World'

    it 'can be turned off', ->
        check = []
        x =
            a: 'Hello'
        x.react 'before after', (object, property, value) ->
            check.push
                object: object
                property: property
                value: value
        x.react 'off'
        x.a = 'Hello World'
        expect(check).to.eql []

    it 'bubbles up an object graph', ->
        deep =
            nested:
                a: 'Hello'
        check = []
        deep.react 'after', (object, property, value) ->
            check.push [object, property, value]
        deep.nested.react 'after', (object, property, value) ->
            check.push [object, property, value]
        deep.nested.a = 'Hello World'
        expect(check).to.eql [
            [deep.nested, 'a', 'Hello World'],
            [deep.nested, 'a', 'Hello World'],
        ]

    it 'understands arrays', ->
        x =
            a: []
        check = []
        x.react 'after', (object, property, value) ->
            check.push [object, property, value]
        x.a.push 'Hi'
        expect(check).to.eql [
            [x, 'a', ['Hi']]
        ]

    it 'understands objects in arrays', ->
        x =
            a: []
        check = []
        x.react 'after', (object, property, value) ->
            check.push [object, property, value]
        x.a.push
            m: 'Hello'
        x.a[0].m = 'Hello World'
        expect(check).to.eql [
            [x, 'a', x.a]
            [x.a[0], 'm', 'Hello World']
        ]

    it 'will re-proxy after you add properties', ->
        x =
            a: 'Hi'
        check = []
        x.react 'after', (object, property, value) ->
            check.push [object, property, value]
        #added property
        x.b = 'There'
        x.react()
        x.b = 'World'
        expect(check).to.eql [
            [x, 'b', 'World']
        ]



