Array::pop = (index=@length-1) -> @splice(index, 1)[0]
Array::random = -> @[Math.floor(@length * Math.random())]
$::css_center = (max_width) -> @css('left', (max_width - @width()) / 2)

stage_height = 300
stage_width = 1000
font_height = 18


class ShootingWord
    constructor: (@full) ->
        @remain = @full
        @speed = 180
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
        @frames = 60
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
        @lives = 3
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
                @lvl = Math.floor(Math.log(Math.max(Math.E, @score)))
                inventory.clear()
            else if not @pair?
                inventory.add(@word)
            else
                inventory.remove(@word)
            pool.autofill()
            @word = null
            @pair = null

    show_lives: ->
        if @lives > 3
            'lives: ♥x' + @lives
        else if @lives > 0
            'lives: ' + ('♥' for [0...Math.max(@lives, 0)]).join('')
        else
            'lives: ☠'

    show_lvl: ->
        'level: ' + @lvl

    show_score: ->
        'score: ' + @score


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
        for [0...Math.max(player.lvl-@words.length, 0)]
            @add()

    loop: ->
        for word in @words
            word.move()

    attack: ->
        (@words.filter (word) -> word.left <= 0).length

    clean: ->
        if player.word?.left <= 0
            player.word = null
            player?.pair.reset()
        @words = @words.filter (word) -> word.left > 0

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
        for word, i in @words
            score += word.full.length * Math.max(player.lvl-i, 1)
        score

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
        @id = setInterval(@loop, 7)

    pause: ->
        @id = clearInterval(@id)

    stop: ->
        @pause()

    reset: ->
        for reinit_object in [player, inventory, pool]
            reinit_object.constructor()

    loop: =>
        fps.loop()
        pool.loop()
        $('#score').html(player.show_score())
        $('#lvl').html(player.show_lvl())
        $('#keep').html(inventory.show()).css_center(stage_width)
        $('#fps').html(fps.show()).css_center(stage_width)
        $('#playground').html(word.repr for word in pool.words)
        if (damage = pool.attack())
            player.lives -= damage
            pool.clean()
            pool.autofill()
        $('#lives').html(player.show_lives())
        if player.lives <= 0
            @stop()
            @reset()
            $('#playground').css('background-color', 'darkred')
            # TODO $( game_summary ) whatever


$(document).keydown (event) ->
    hotkeys =
        erase: [8, 46] # backspace, delete
        pause: [27] # esc
        start: [13] # enter
        howto: [72] # h
        gotit: [13] # enter
    for id, keys of hotkeys
        button = $("##{id}")
        if button.is(':visible') and event.keyCode in keys
            return button.click()


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
    $('.tool').hide()
    $('#tutorial').hide()

    $('#start').click ->
        animate.start()
        pool.easter_egg()
        $('#menu').hide()
        $('.tool').show()
        $('#playground').css('background-color', 'lightblue')

    $('#howto').click ->
        $('#menu').hide()
        $('#tutorial').show().css_center(stage_width)

    $('#gotit').click ->
        $('#tutorial').hide()
        $('#menu').show().css_center(stage_width)

    $('#erase').click ->
        player.reset()

    $('#pause').click ->
        animate.pause()
        $('#menu').show().css_center(stage_width)
        $('.tool').hide()
