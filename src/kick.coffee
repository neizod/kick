Array::pop = (index=@length-1) -> @splice(index, 1)[0]
Array::random = -> @[Math.floor(@length * Math.random())]
$::css_center = (max_width) -> @css('left', (max_width - @width()) / 2)

stage_height = 300
stage_width = 1000
font_height = 18


class ShootingWord
    constructor: (@full) ->
        @remain = @full
        @speed = 80
        @top = (stage_height - font_height) * Math.random()
        @left = stage_width
        @repr = @make_repr()
        @update()

    make_repr: ->
        $('<div>').addClass('absolute')
                  .css('top', @top)
                  .css('left', @left)

    done: ->
        @full.slice(0, @full.length - @remain.length)

    shot: (c) ->
        if c == @remain[0]
            @remain = @remain.slice(1)
        @update()

    move: ->
        @left -= @speed / fps.rate()
        @repr.css('left', @left)

    update: ->
        if @remain == @full
            @repr.html($('<b>').html(@full))
        else
            @repr.html([$('<u>').html(@done()), $('<b>').html(@remain)])

    reset: ->
        @remain = @full
        @update()


fps = new class
    constructor: ->
        @frames = 20
        @actual = 0
        @time = 0
        @date = new Date()

    loop: ->
        if @actual != @frames
            @actual += 1
        now = new Date()
        @time += (now - @date - @time) / @actual
        @date = now

    rate: ->
        1000 / @time

    show: ->
        @rate().toFixed(1) + ' fps'


player = new class
    constructor: ->
        @lvl = 1
        @score = 0
        @die = false
        @word = null
        @pair = null
        @longest = []

    reset: ->
        @word?.reset()
        @word = null
        @pair?.reset()
        @pair = null

    shoot: (c) ->
        @word?.shot(c) and @pair?.shot(c)
        if @word?.remain == ''
            pool.remove(@word)
            if @word.full == inventory.name?.full
                @score += inventory.scoring()
                inventory.clear()
            else if not @pair?
                inventory.add(@word)
            else
                inventory.remove(@word)
            pool.autofill()
            @lvl += 1
            @word = null
            @pair = null


class WordKeeper
    get: (str) ->
        for word, i in @words
            comparator = if str.length == 1 then word.remain[0] else word.full
            if str == comparator
                return @words[i]

    remove: (word) ->
        if (index = @index(word))?
            @words.pop(index)

    index: (find) ->
        for word, i in @words
            if word.full == find.full
                return i


pool = new class extends WordKeeper
    constructor: ->
        @words = []
        @actions = ['box', 'kick', 'punch', 'strike']
        @autofill()

    add: (word=@actions.random()) ->
        @words.push(new ShootingWord(word))

    autofill: ->
        for [1..player.lvl-@words.length]
            @add()

    loop: ->
        for word in @words
            word.move()

    attack: ->
        @words.some (word) -> word.left <= 0

    easter_egg: ->
        if animate.id == 1
            @words = []
            @add('kick')


inventory = new class extends WordKeeper
    constructor: ->
        @words = []
        @name = null

    add: (word) ->
        word.reset()
        @words.push(word)
        if not @name?
            @name = new ShootingWord('@neizod')

    remove: (word) ->
        super
        if not @words.length
            @name = null

    get_name: (c) ->
        if c == @name?.remain[0]
            return @name

    scoring: ->
        score = 0
        for word in @words
            score += word.full.length
        score * player.lvl

    clear: ->
        if @words.length >= player.longest.length
            player.longest = @words
        @name = null
        @words = []

    show: ->
        sentence = @words.concat(if @name? then [@name] else [])
        (word.repr.html() for word in sentence).join(' ')


animate = new class
    constructor: ->
        @id = null

    start: ->
        fps.constructor()
        @id = setInterval(@loop, 12)
        $('#playground').css('background-color', 'lightblue')
        $('#menu').hide()

    pause: ->
        @id = clearInterval(@id)
        $('#menu').show().css_center(stage_width)

    stop: ->
        @pause()
        $('#playground').css('background-color', 'darkred')

    reset: ->
        for reinit_object in [player, inventory, pool]
            reinit_object.constructor()

    loop: =>
        fps.loop()
        pool.loop()
        $('#score').html(player.score)
        $('#keep').html(inventory.show()).css_center(stage_width)
        $('#fps').html(fps.show()).css_center(stage_width)
        $('#playground').html(word.repr for word in pool.words)
        player.die = true if pool.attack()
        if player.die
            @stop()
            @reset()


$(document).keydown (event) ->
    if not animate.id?
        if event.keyCode == 13 # enter
            animate.start()
            pool.easter_egg()
    else
        if event.keyCode == 27 # escape
            animate.pause()
        if event.keyCode in [8, 46] # backspace, delete
            player.reset()


$(document).keypress (event) ->
    return if not animate.id?
    c = String.fromCharCode(event.charCode)
    if not player.word?
        player.word = pool.get(c)
    if player.word?
        if player.word.full == player.word.remain
            player.pair = inventory.get(player.word.full)
    else
        player.word = inventory.get_name(c)
    player.shoot(c)


$(document).ready ->
    $('#menu').show().css_center(stage_width)
    $('#tutorial').hide()

    $('#start').click ->
        animate.start()
        pool.easter_egg()

    $('#howto').click ->
        $('#menu').hide()
        $('#tutorial').show().css_center(stage_width)

    $('#gotit').click ->
        $('#tutorial').hide()
        $('#menu').show().css_center(stage_width)
