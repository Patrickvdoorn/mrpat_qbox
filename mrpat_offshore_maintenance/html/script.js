function setLabels(game, labels) {
	document.getElementById(game + 'Title').textContent = labels.title;
	document.getElementById(game + 'Hint').innerHTML = labels.hint;
}

let currentGame = null;
let triesLeft = 3;
const MAX_FRAME_TIME = 0.05;

//VOLTMETER
const voltmeterBox = document.getElementById('voltmeter');
const zone = document.getElementById('zone');
const needle = document.getElementById('needle');
const volts = document.getElementById('volts');
const voltmeterStatus = document.getElementById('voltmeterStatus');

let voltmeterRunning = false;
let position = 0;
let direction = 1;
let zoneStart = 0;
let speed = 60;
let zoneWidth = 15;
let voltmeterLabels = {};
let voltmeterLastTime = 0;

//BOLTS
const boltsBox = document.getElementById('bolts');
const boltEls = document.querySelectorAll('.bolt');
const boltsStatus = document.getElementById('boltsStatus');

let boltShowTime = 700;
let sequence = [];
let boltTimers = [];
let step = 0;
let acceptingInput = false;
let boltsLabels = {}

//WIRES
const wiresBox = document.getElementById('wires');
const wiresBoard = document.getElementById('wireBoard');
const wiresLeft = document.getElementById('wiresLeft');
const wiresRight = document.getElementById('wiresRight');
const wiresSvg = document.getElementById('wireSvg');
const wiresStatus = document.getElementById('wiresStatus');

const wiresColors = ['#e74c3c', '#3498db', '#f1c40f', '#2ecc71', '#9b59b6', '#e67e22'];

let wiresLabels = {};
let wiresConnected = 0;
let wiresCount = 0;
let dragFrom = null;
let dragLine = null;

//STEADY
const steadyBox = document.getElementById('steady');
const steadyZone = document.getElementById('steadyZone');
const steadyIndicator = document.getElementById('steadyIndicator');
const steadyFill = document.getElementById('steadyFill');
const steadyPercent = document.getElementById('steadyPercent');

let steadyLabels = {};
let steadyRunning = false;
let steadyHolding = false;
let steadySettings = {};
let steadyLastTime = 0;
let steadyElapsed = 0;

let indicatorPos = 0;
let indicatorVel = 0;
let zoneCenter = 50;
let zoneTarget = 50;
let steadyProgress = 0;

// PUMPING
const pumpingBox = document.getElementById('pumping');
const pumpWater = document.getElementById('pumpWater');
const pumpPressure = document.getElementById('pumpPressure');
const pumpGauge = document.querySelector('.pump-gauge');
const pumpingStatus = document.getElementById('pumpingStatus');

let pumpingRunning = false;
let pumpingSettings = {};
let pumpingLabels = {};
let pumpingLastTime = 0;
let pumpingElapsed = 0;

let waterLevel = 100;
let pressure = 0;
let lastPumpKey = null;
let jammedUntil = 0;

// CODE
const codeBox = document.getElementById('code');
const codeHistory = document.getElementById('codeHistory');
const codeInput = document.getElementById('codeInput');
const codeStatus = document.getElementById('codeStatus');

let codeLabels = {};
let codeSecret = [];
let codeGuess = [];
let codeLength = 4;
let codeAttempts = 6;

window.addEventListener('message', (event) => {
	const data = event.data;
	if (data.action === 'open' && data.game === 'voltmeter') {
		/* VOLTMETER */
		currentGame = data.game;
		voltmeterLabels = data.labels || {};
		setLabels('voltmeter', voltmeterLabels);
		
		voltmeterStatus.textContent = '';
		direction = 1;
		speed = data.settings.speed || 60;
		zoneWidth = data.settings.zoneWidth || 15;
		triesLeft = data.settings.tries || 3;

		voltmeterBox.classList.add('show');
		zoneStart = 10 + Math.random() * (80 - zoneWidth);
		zone.style.left = zoneStart + '%';
		zone.style.width = zoneWidth + '%';
		position = 0;

		voltmeterRunning = true;
		voltmeterLastTime = performance.now();
		requestAnimationFrame(voltmeterTick);

	} else if (data.action === 'open' && data.game === 'bolts') {
		/* BOLTS */
		currentGame = data.game;
		boltsLabels = data.labels || {};
		setLabels('bolts', boltsLabels);
		
		const count = Math.min(data.settings.count || 3, boltEls.length);
		boltShowTime = data.settings.showTime || 700;
		triesLeft = data.settings.tries || 3;
		
		clearBoltTimers();

		sequence = shuffled([...boltEls].map((b, i) => i)).slice(0, count);

		step = 0;
		acceptingInput = false;
		boltEls.forEach(b => b.classList.remove('lit', 'done', 'wrong', 'clickable'));
		boltsStatus.textContent = boltsLabels.watch || 'WATCH';
		boltsBox.classList.add('show');

		showSequence(boltShowTime);

	} else if (data.action === 'open' && data.game === 'wires') {
		/* WIRES */
		currentGame = data.game;
		wiresLabels = data.labels || {};
		setLabels('wires', wiresLabels);
		
		wiresCount = Math.min(data.settings.count || 4, wiresColors.length);
		wiresConnected = 0;
		triesLeft = data.settings.tries || 3;

		wiresLeft.innerHTML = '';
		wiresSvg.innerHTML = '';
		wiresRight.innerHTML = '';
		wiresStatus.textContent = '';

		const colors = wiresColors.slice(0, wiresCount);
		const leftOrder = shuffled(colors);
		const rightOrder = shuffled(colors);
		leftOrder.forEach(color => wiresLeft.appendChild(makeWireEnd(color, 'left')));
		rightOrder.forEach(color => wiresRight.appendChild(makeWireEnd(color, 'right')));

		wiresBox.classList.add('show');

	} else if (data.action === 'open' && data.game === 'steady') {
		/* STEADY */
		currentGame = data.game;
		steadyLabels = data.labels || {};
		setLabels('steady', steadyLabels);

		steadySettings = {
			zoneSize: data.settings.zoneSize || 24,
			zoneSpeed: data.settings.zoneSpeed || 1.0,
			fillRate: data.settings.fillRate || 15,
			drainRate: data.settings.drainRate || 14,
			timeLimit: data.settings.timeLimit || 20,
		}

		indicatorPos = 50;
		indicatorVel = 0;
		zoneCenter = 50;
		zoneTarget = 50;
		steadyProgress = 50;
		steadyElapsed = 0;
		steadyHolding = false;

		
		steadyBox.classList.add('show');
		steadyRunning = true
		steadyLastTime = performance.now();
		requestAnimationFrame(steadyTick);

	} else if (data.action === 'open' && data.game === 'pumping') {
		/* PUMPING */
		currentGame = data.game;
		pumpingLabels = data.labels || {};
		setLabels('pumping', pumpingLabels);

		pumpingSettings = {
			strokePower: data.settings.strokePower || 5,
			leakRate: data.settings.leakRate || 4,
			pressurePerStroke: data.settings.pressurePerStroke || 14,
			coolRate: data.settings.coolRate || 25,
			timeLimit: data.settings.timeLimit || 25,
		};
		triesLeft = data.settings.tries || 3;

		waterLevel = 100;
		pressure = 0;
		lastPumpKey = null;
		jammedUntil = 0;
		pumpingElapsed = 0;
		pumpingStatus.textContent = '';
		pumpPressure.classList.remove('danger');
		pumpGauge.classList.remove('jammed');

		pumpingBox.classList.add('show');
		pumpingRunning = true;
		pumpingLastTime = performance.now();
		requestAnimationFrame(pumpingTick);


	} else if (data.action === 'open' && data.game === 'code') {
		/* CODE */
		currentGame = data.game;
		codeLabels = data.labels || {};
		setLabels('code', codeLabels);

		codeLength = Math.min(data.settings.length || 4, 6);
		codeAttempts = data.settings.attempts || 6;
		codeSecret = shuffled([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]).slice(0, codeLength);
		codeGuess = [];

		codeHistory.innerHTML = '';
		renderCodeInput();
		updateCodeStatus();

		codeBox.classList.add('show');

	} else if (data.action === 'close') {

		resetMinigames();
	}
});


// VOLTMETER
const VOLTMETER_MAX_VOLTS = 15;
function voltmeterTick(now) {
	if (!voltmeterRunning) return;

	const dt = Math.min((now - voltmeterLastTime) / 1000, MAX_FRAME_TIME);
	voltmeterLastTime = now;
	
	position = position + (speed * direction * dt);
	position = Math.max(0, Math.min(100, position));
	if (position >= 100 || position <= 0) {
		direction = direction * -1;
	}
	needle.style.left = position + '%';
	volts.textContent = (position / 100 * VOLTMETER_MAX_VOLTS).toFixed(1);
	requestAnimationFrame(voltmeterTick);
}

// BOLTS
function boltTimeout(fn, ms) {
	boltTimers.push(setTimeout(fn, ms));
}

function clearBoltTimers() {
	boltTimers.forEach(id => clearTimeout(id));
	boltTimers = [];
}

function showSequence(showTime) {
	const start = 500;

	sequence.forEach((boltIndex, i) => {
		const t = start + i * showTime * 2;
		boltTimeout(() => boltEls[boltIndex].classList.add('lit'), t);
		boltTimeout(() => boltEls[boltIndex].classList.remove('lit'), t + showTime);
	});

	boltTimeout(() => {
		acceptingInput = true;
		boltsStatus.textContent = boltsLabels.go || 'GO';
		boltEls.forEach(b => b.classList.add('clickable'));
	}, start + sequence.length * showTime * 2);
}

function finishBolts(success) {
	acceptingInput = false;
	currentGame = null;
	boltEls.forEach(b => b.classList.remove('clickable'));

	boltTimeout(() => {
		boltsBox.classList.remove('show');
		sendResult(success);
	}, 600);
}

function restartBolts(showTime) {
	step = 0;
	acceptingInput = false;
	boltEls.forEach(b => b.classList.remove('lit', 'done', 'wrong', 'clickable'));
	boltsStatus.textContent = boltsLabels.watch || 'WATCH';

	showSequence(showTime);
}

boltEls.forEach(bolt => {
	bolt.addEventListener('click', () => {
		if (!acceptingInput) return;

		const index = Number(bolt.dataset.index);

		if (index == sequence[step]) {
			bolt.classList.add('done');
			step++;
			if (step === sequence.length) {
				finishBolts(true);
			}
		} else {
			bolt.classList.add('wrong');
			acceptingInput = false;
			triesLeft--;

			if (triesLeft <= 0) {
				finishBolts(false);
			} else {
				boltsStatus.textContent = (boltsLabels.retry || 'TRY AGAIN') + ' (' + triesLeft + ')';
				boltTimeout(() => restartBolts(boltShowTime), 1000);
			}			
		}
	})
})

// WIRES
function centerOf (el) {
	const board = wiresBoard.getBoundingClientRect();
	const r = el.getBoundingClientRect();
	return { x: r.left + r.width / 2 - board.left, y: r.top + r.height / 2 - board.top };
}

function makeLine(from, to, color) {
	const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
	line.setAttribute('x1', from.x);
	line.setAttribute('y1', from.y);
	line.setAttribute('x2', to.x);
	line.setAttribute('y2', to.y);
	line.setAttribute('stroke', color);
	wiresSvg.appendChild(line);
	return line;
}

function makeWireEnd(color, side) {
	const end = document.createElement('div');
	end.className = 'wire-end';
	end.style.background = color;
	end.dataset.color = color;
	end.dataset.side = side;
	return end;
}

wiresLeft.addEventListener('mousedown', (e) => {
	if (currentGame !== 'wires') return;

	const end = e.target;
	if (!end.classList.contains('wire-end')) return;
	if (end.classList.contains('connected')) return;

	dragFrom = end;
	const start = centerOf(end);
	dragLine = makeLine(start, start, end.dataset.color);
});

wiresBoard.addEventListener('mousemove', (e) => {
	if (!dragLine) return;

	const board = wiresBoard.getBoundingClientRect();
	dragLine.setAttribute('x2', e.clientX - board.left);
	dragLine.setAttribute('y2', e.clientY - board.top);
});

window.addEventListener('mouseup', (e) => {
	if (!dragLine) return;

	const line = dragLine;
	const from = dragFrom;
	dragLine = null;
	dragFrom = null;

	const target = document.elementFromPoint(e.clientX, e.clientY);
	const isRightEnd = target && target.classList.contains('wire-end') && target.dataset.side === 'right';

	if (!isRightEnd) {
		line.remove();
		return;
	}

	if (target.dataset.color === from.dataset.color && !target.classList.contains('connected')) {
		const end = centerOf(target);
		line.setAttribute('x2', end.x);
		line.setAttribute('y2', end.y);
		from.classList.add('connected');
		target.classList.add('connected');
		wiresConnected++;

		if (wiresConnected === wiresCount) {
			currentGame = null;
			setTimeout(() => {
				wiresBox.classList.remove('show');
				sendResult(true);
			}, 600);
		}
		return;
	}

	line.classList.add('wrong');
	setTimeout(() => line.remove(), 400);
	triesLeft--;

	if (triesLeft <= 0) {
		currentGame = null;
		setTimeout(() => {
				wiresBox.classList.remove('show');
				sendResult(false);
			}, 600);

	} else {
		wiresStatus.textContent = (wiresLabels.retry || 'TRY AGAIN') + ' (' + triesLeft + ')';
	}
});

// STEADY
const STEADY_ACCEL_UP = 260;
const STEADY_GRAVITY = 200;
const STEADY_MAX_SPEED = 90;
const STEADY_ZONE_BASE_SPEED = 35;

function steadyTick(now) {
	if (!steadyRunning) return;

	const dt = Math.min((now - steadyLastTime) / 1000, MAX_FRAME_TIME);
	steadyLastTime = now;
	steadyElapsed += dt;

	const s = steadySettings;

	const accel = steadyHolding ? STEADY_ACCEL_UP : -STEADY_GRAVITY;
	indicatorVel += accel * dt;
	indicatorVel = Math.max(-STEADY_MAX_SPEED, Math.min(STEADY_MAX_SPEED, indicatorVel));
	indicatorPos += indicatorVel * dt;

	if (indicatorPos <= 0) { indicatorPos = 0; indicatorVel = 0; }
	if (indicatorPos >= 100) { indicatorPos = 100; indicatorVel = 0; }

	const half = s.zoneSize / 2;
	const step = STEADY_ZONE_BASE_SPEED * s.zoneSpeed * dt;
	if (Math.abs(zoneTarget - zoneCenter) <= step) {
		zoneTarget = half + Math.random() * (100 - s.zoneSize);
	}
	zoneCenter += Math.sign(zoneTarget - zoneCenter) * step;

	const inside = Math.abs(indicatorPos - zoneCenter) <= half;
	steadyProgress += (inside ? s.fillRate : -s.drainRate) * dt;
	steadyProgress = Math.max(0, Math.min(100, steadyProgress));

	steadyZone.style.bottom = (zoneCenter - half) + '%';
	steadyZone.style.height = s.zoneSize + '%';
	steadyIndicator.style.bottom = indicatorPos + '%';
	steadyIndicator.classList.toggle('inside', inside);
	steadyFill.style.width = steadyProgress + '%';
	steadyPercent.textContent = Math.floor(steadyProgress);

	if (steadyProgress >= 100) return finishSteady(true);
	if (steadyProgress <= 0 || steadyElapsed >= s.timeLimit) return finishSteady(false);

	requestAnimationFrame(steadyTick);
}

function finishSteady(success) {
	steadyRunning = false;
	currentGame = null;
	setTimeout(() => {
				steadyBox.classList.remove('show');
				sendResult(success);
			}, 600);
}

window.addEventListener('keyup', (event) => {
	if (event.code !== 'Space' || currentGame !== 'steady') return;

	steadyHolding = false;
});

// PUMPING
const PUMP_DANGER_PRESSURE = 80;
const PUMP_MAX_PRESSURE = 100;

function pumpingTick(now) {
	if (!pumpingRunning) return;

	const dt = Math.min((now - pumpingLastTime) / 1000, MAX_FRAME_TIME);
	pumpingLastTime = now;
	pumpingElapsed += dt;

	const s = pumpingSettings;

	waterLevel = Math.min(100, waterLevel + s.leakRate * dt);
	pressure = Math.max(0, pressure - s.coolRate * dt);

	if (jammedUntil && now >= jammedUntil) {
		jammedUntil = 0;
		pumpGauge.classList.remove('jammed');
		pumpingStatus.textContent = '';
	}

	pumpWater.style.height = waterLevel + '%';
	pumpPressure.style.height = pressure + '%';
	pumpPressure.classList.toggle('danger', pressure >= PUMP_DANGER_PRESSURE);

	if (pumpingElapsed >= s.timeLimit) return finishPumping(false);

	requestAnimationFrame(pumpingTick);
}

function pumpStroke(key) {
	const now = performance.now();
	if (now < jammedUntil) return;
	if (key === lastPumpKey) return;
	lastPumpKey = key;

	const s = pumpingSettings;
	waterLevel = Math.max(0, waterLevel - s.strokePower);
	pressure += s.pressurePerStroke;

	if (waterLevel <= 0) {
		pumpWater.style.height = '0%';
		return finishPumping(true);
	}

	if (pressure >= PUMP_MAX_PRESSURE) {
		triesLeft--;
		if (triesLeft <= 0) return finishPumping(false);

		pressure = 40;
		jammedUntil = now + 1500;
		pumpGauge.classList.add('jammed');
		pumpingStatus.textContent = (pumpingLabels.jammed || 'JAMMED') + ' (' + triesLeft + ')';
	}
}

function finishPumping(success) {
	pumpingRunning = false;
	currentGame = null;
	setTimeout(() => {
		pumpingBox.classList.remove('show');
		sendResult(success);
	}, 600);
}

// CODE
function makeDigit(text, className) {
	const digit = document.createElement('div');
	digit.className = 'code-digit';
	if (className) digit.classList.add(className);
	digit.textContent = text;
	return digit;
}

function renderCodeInput() {
	codeInput.innerHTML = '';
	for (let i = 0; i < codeLength; i++) {
		const digit = makeDigit(codeGuess[i] ?? '', i === codeGuess.length ? 'active': null);
		codeInput.appendChild(digit);
	}
}

function updateCodeStatus() {
	codeStatus.textContent = (codeLabels.attempts || 'TRIES') + ' ' + codeAttempts;
}

function scoreGuess(guess) {
	return guess.map((digit,i) => {
		if (digit === codeSecret[i]) return 'correct';
		if (codeSecret.includes(digit)) return 'present';
		return 'absent';
	});
}

function submitCode()  {
	if (codeGuess.length < codeLength) {
		codeInput.classList.remove('shake');
		void codeInput.offsetWidth;
		codeInput.classList.add('shake');
		return;
	}

	const results = scoreGuess(codeGuess);
	const row = document.createElement('div');
	row.className = 'code-row';
	codeGuess.forEach((digit, i) => row.appendChild(makeDigit(digit, results[i])));
	codeHistory.appendChild(row);

	codeAttempts--;
	codeGuess = [];

	if (results.every(r => r === 'correct')) return finishCode(true);
	if (codeAttempts <= 0) return finishCode(false);

	renderCodeInput();
	updateCodeStatus();
}

function handleCodeKey(event) {
	if (event.key >= '0' && event.key <= '9' && event.key.length === 1) {
		const digit = Number(event.key);
		if (codeGuess.length < codeLength && !codeGuess.includes(digit)) {
			codeGuess.push(digit);
			renderCodeInput();
		}	
	} else if (event.code === 'Backspace') {
		codeGuess.pop();
		renderCodeInput();
	} else if (event.code === 'Enter' || event.code === 'NumpadEnter') {
		submitCode();
	}
}

function finishCode(success) {
	currentGame = null;
	codeInput.innerHTML = '';

	if (!success) {
		codeSecret.forEach(digit => codeInput.appendChild(makeDigit(digit, 'absent')));
	}

	setTimeout(() => {
		codeBox.classList.remove('show');
		sendResult(success);
	}, success ? 800 : 1800);
}

// GENERIC
window.addEventListener('keydown', (event) => {
	if (event.repeat) return;
	if (event.code === 'Space' && currentGame === 'voltmeter') {
		
		const hit = position >= zoneStart && position < (zoneStart + zoneWidth);

		if (hit) {
			voltmeterRunning = false;
			currentGame = null;
			setTimeout(() => {				
				voltmeterBox.classList.remove('show');
				sendResult(true);
				}, 600);
			return;
		}

		triesLeft--;
		
		if (triesLeft <= 0) {
			voltmeterRunning = false;
			currentGame = null;
			setTimeout(() => {	
				voltmeterBox.classList.remove('show');
				sendResult(false);
				}, 600);
			return
		} 
		
		voltmeterStatus.textContent = (voltmeterLabels.retry || 'TRY AGAIN') + ' (' + triesLeft + ')';
	} else if (event.code == 'Space' && currentGame == 'steady') {
		steadyHolding = true;
	} else if ((event.code === 'KeyA' || event.code === 'KeyD') && currentGame === 'pumping') {
		pumpStroke(event.code);
	} else if (currentGame === 'code') {
		handleCodeKey(event);
	}
});

function resetMinigames() {
	currentGame = null;

	//voltmeter
	voltmeterRunning = false;

	//bolts
	acceptingInput = false;
	clearBoltTimers();

	//wires
	if (dragLine) dragLine.remove();
	dragFrom = null;
	dragLine = null;

	//steady
	steadyRunning = false;
	steadyHolding = false;

	//pumping
	pumpingRunning = false;
	jammedUntil = 0;
	pumpGauge.classList.remove('jammed');

	//code
	codeGuess = [];

	document.querySelectorAll('.minigame').forEach(el => el.classList.remove('show'));
}

function shuffled(list) {
	const copy = [...list];
	for (let i = copy.length - 1; i > 0; i--) {
		const j = Math.floor(Math.random() * (i + 1));
		[copy[i], copy[j]] = [copy[j], copy[i]];
	}
	return copy;
}

window.addEventListener('keydown', (event) => {
	if (event.key === 'Escape' && currentGame) {
		resetMinigames();
		sendResult(false);
	}
});

function sendResult(success) {
	fetch(`https://${GetParentResourceName()}/result`, {
		method: 'POST',
		body: JSON.stringify({success: success })
	});
}