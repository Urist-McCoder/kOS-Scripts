@LazyGlobal off.

// all formulas taken from http://ksp.olex.biz/js/kspcalc.js, I have no idea how any of these work
// returns List(phase angle, burn Δv, ejection angle)
global function interplanetaryTransfer {
    parameter origin.
    parameter target.
    parameter parkingOrbitAlt is ship:altitude.

    local parent is origin:body.
    if (parent <> target:body) {
        // wait, that's illegal
        print 1 / 0.
    }

    local oAlt is (origin:position - parent:position):mag.
    local tAlt is (target:position - parent:position):mag.

    local t_h is constant:PI * sqrt((oAlt + tAlt)^3 / (8 * parent:mu)).
    local phase is mod(540 - sqrt(parent:mu / tAlt) * (t_h / tAlt) * constant:radToDeg, 360).

    local exitAlt is oAlt + origin:soiRadius.
    local v2 is sqrt(parent.mu / exitAlt) * (sqrt((2 * tAlt) / (exitAlt + tAlt)) - 1).
    local r is origin:radius + parkingOrbitAlt.
    local v is sqrt((r * (origin:soiRadius * v2 * v2 - 2 * origin:mu) + 2 * origin:soiRadius * origin:mu) / (r * origin:soiRadius)).
    local v0 is sqrt(origin:mu / r).
    local dV is v - v0.

    local eta is (v * v / 2) - (origin:mu / r).
    local h is r * v.
    local e is sqrt(1 + (2 * eta * h * h) / (origin:mu * origin:mu)).
    local eject is mod(180 - (arccos(1 / e) * constant:radToDeg), 360).

    if (e < 1) {
        local a is -origin:mu / (2 * eta).
        local L is a * (1 - e * e). // lower case 'l' looks like number 1
        local nu is arccos((L - origin:soiRadius) / (e * origin:soiRadius)).
        local phi is arcTan2(e * sin(nu), 1 + e * cos(nu)).

        set eject to mod(90 - (phi * constant:radToDeg) + (nu * constant:radToDeg), 360).
    }

    return List(phase, dv, eject).
}