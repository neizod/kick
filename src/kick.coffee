Array::pop = (index=@length-1) -> @splice(index, 1)[0]
Array::random = -> @[Math.floor(@length * Math.random())]
$::css_center = (max_width) -> @css('left', (max_width - @width()) / 2)
$::clear_pos = -> @css('left', '') and @css('top', '')

stage_height = 300
stage_width = 1000


tweet = (text) ->
    url = 'http://neizod.github.io/kick'
    $('#tweet').html $('<a>').addClass('twitter-share-button')
                             .html('tweet')
                             .attr('href', 'https://twitter.com/share')
                             .attr('data-text', text)
                             .attr('data-url', url)
                             .attr('data-lang', 'en')
                             .attr('data-count', 'vertical')
                             .attr('data-counturl', url)
    twttr?.widgets.load()


class ShootingWord
    constructor: (@full) ->
        @remain = @full
        @speed = 110
        if player.lvl < 10
            @speed += player.lvl * (25 - player.lvl) / 2
        else
            @speed += player.lvl * 4 + 36
        @repr = $('<div>').addClass('absolute')
        @update()
        $('#placeholder').html(@repr)
        @top = (stage_height - @repr.height()) * Math.random()
        @left = stage_width - @repr.width()
        @repr.css('top', @top).css('left', @left)
        $('#placeholder').empty()

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


boss = new class
    constructor: ->
        @status = 'normal'

    reset: ->
        @constructor()
        $('#boss').attr('class', 'absolute')
                  .addClass(@status)

    sleep: ->
        $('#boss').removeClass(@status)
                  .addClass('sleep')

    awake: ->
        $('#boss').removeClass('sleep')
                  .addClass(@status)

    update: (lvl=player.lvl) ->
        $('#boss').removeClass(@status)
        if lvl > 7
            @status = 'tear'
        else
            @status = [ 'love', 'normal', 'ennui', 'curious',
                        'exclaim', 'angry', 'wtf', 'wth',   ][lvl]
        $('#boss').addClass(@status)


player = new class
    constructor: ->
        @lvl = 1
        @lives = 3
        @score = 0
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
                @score += 1
                inventory.add(@word)
            else
                inventory.remove(@word)
            if @lvl < Math.floor(Math.log(Math.E + @score))
                @lvl += 1
                @lives += 1
                boss.update()
            pool.autofill()
            @word = null
            @pair = null

    show_lives: ->
        if @lives > 3
            'lives: ♥×' + @lives
        else if @lives > 0
            'lives: ' + ('♥' for [0...Math.max(@lives, 0)]).join('')
        else
            'lives: ☠'

    show_lvl: ->
        'level: ' + @lvl

    show_score: ->
        'score: ' + @score

    make_summary: ->
        @make_tweet()
        $('#summary').html("<p>game over, your score is <u>#{@score}</u>.</p>")
                     .append('<p>click below to tweet your score!</p>')
                     .show()

    make_tweet: ->
        unless @longest.length
            return tweet('i got kicked by @neizod.')
        url_preserve_length = 23
        score = " @neizod and score #{@score}!"
        quota = 140 - url_preserve_length - score.length
        sentence = 'i'
        for word in @longest
            if sentence.length + 1 + word.full.length >= quota
                break
            sentence += ' ' + word.full
        tweet(sentence + score)


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

    actions: null

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
            player.pair?.reset()
        @words = @words.filter (word) -> word.left > 0

    easter_egg: (force=false) ->
        if animate.id == 1 or force
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
        pool.autofill()
        @id = setInterval(@loop, 7)
        @toggle_tools()

    pause: ->
        @id = clearInterval(@id)
        @toggle_tools()

    stop: ->
        @pause()

    reset: ->
        for reinit_object in [player, inventory, pool]
            reinit_object.constructor()

    alive: ->
        $('#playground').removeClass('dead').addClass('alive')

    dead: ->
        $('#playground').removeClass('alive').addClass('dead')

    loop: =>
        fps.loop()
        pool.loop()
        $('#score').html(player.show_score())
        $('#lvl').html(player.show_lvl())
        $('#keep').html(inventory.show()).css_center(stage_width)
        $('#fps').html(fps.show())
        $('#playground').html(word.repr for word in pool.words)
        if (damage = pool.attack())
            player.lives -= damage
            pool.clean()
            pool.autofill()
        $('#lives').html(player.show_lives())
        if player.lives <= 0
            if player.score == 0
                boss.update(0)
            player.make_summary()
            @stop()
            @reset()
            @toggle_tools()
            @dead()
            $('#start').html('play again!')
            $('#menu').show().css_center(stage_width)

    toggle_tools: ->
        if animate.id
            $('#pause').show()
            $('#resume').hide()
            $('#erase').prop('disabled', false)
        else
            $('#pause').hide()
            $('#resume').show()
            $('#erase').prop('disabled', true)


tutorial = new class
    constructor: ->
        @step = 0
        @all_steps = 4

    reset: ->
        while @step
            @nextstep()
        @sample[0]()

    sample:
        0: ->
            animate.reset()
            $('#score').html(player.show_score())
            $('#lvl').html(player.show_lvl())
            $('#lives').html(player.show_lives())
        1: ->
            pool.easter_egg(true)
            player.word = pool.words[0]
            player.word.repr.clear_pos().attr('id', 'sample-1')
            $('#playground').html(player.word.repr)
        2: ->
            player.word.remain = player.word.full.slice(2)
            player.word.update()
            player.word.repr.clear_pos().attr('id', 'sample-2')
            $('#playground').html(player.word.repr)
        3: ->
            player.word.remain = ''
            player.shoot()
            player.word = inventory.name
            player.word.remain = player.word.full.slice(4)
            player.word.update()
            $('#playground').empty()
            $('#keep').html(inventory.show()).css_center(stage_width)
        4: ->
            player.word.remain = ''
            player.shoot()
            $('#keep').empty()
            $('#score').html(player.show_score())
            $('#lvl').html(player.show_lvl())

    nextstep: ->
        if @step
            $("#step-#{@step}").hide()
        else
            $('#howto').hide()
            $('#start').hide()
            $('.social').hide()
            $('#nextstep').show()
            $('#tutorial').show()
            animate.alive()
        @step += 1
        @step %= @all_steps + 1
        if @step
            $("#step-#{@step}").show()
            if @step == @all_steps
                $('#start').show()
                $('#howto').show()
                $('.social').show()
                $('#nextstep').hide()
        else
            $('#howto').show()
            $('#nextstep').hide()
            $('#tutorial').hide()
        @sample[@step]()


$(document).keydown (event) ->
    hotkeys =
        nextstep: [13, 27] # enter, esc
        howto:    [27] # esc
        erase:    [8, 46] # backspace, delete
        pause:    [27] # esc
        start:    [13] # enter
        resume:   [13, 27] # enter, esc
    for id, keys of hotkeys
        button = $("##{id}")
        clickable_button = button.is(':visible') and not button.is(':disabled')
        if clickable_button and event.keyCode in keys
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
    animate.toggle_tools()
    for pre_hidden in ['#nextstep', '#tutorial', '#summary']
        $(pre_hidden).hide()
    animate.alive()
    boss.reset()
    $('#menu').show().css_center(stage_width)

    $.get 'words.txt', (data) ->
        pool.actions = data.split('\n').filter (word) -> word.length

    $('#start').click ->
        tutorial.reset()
        boss.reset()
        $('#summary').hide()

    $('#start, #resume').click ->
        unless pool.actions
            return $('#keep').html('-- file not ready, please try again. --')
                             .css_center(stage_width)
        animate.start()
        boss.awake()
        pool.easter_egg()
        $('#menu').hide()
        animate.alive()

    $('#howto').click ->
        tutorial.reset()
        boss.reset()
        $('#summary').hide()

    $('#howto, #nextstep').click ->
        tutorial.nextstep()
        $('#menu').show().css_center(stage_width)

    $('#erase').click ->
        player.reset()

    $('#pause').click ->
        animate.pause()
        boss.sleep()
        $('#playground').empty()
        $('#keep').html('-- game pause --').css_center(stage_width)

    tweet("let's play kick @neizod!")
