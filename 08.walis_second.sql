WITH	RECURSIVE
	all_factors (initial, factor, final) AS
	(
	SELECT	s, s, FALSE
	FROM	generate_series(2, 99 * 99) s
	UNION ALL
	SELECT	initial, f, d IN (1, factor)
	FROM	(
		SELECT	initial, factor, d
		FROM	all_factors
		CROSS JOIN
			LATERAL
			(
			SELECT	d
			FROM	generate_series(TRUNC(SQRT(factor))::INTEGER, 1, -1) d
			WHERE	factor % d = 0
			LIMIT 1
			) q (d)
		WHERE	NOT final
		) q
	CROSS JOIN
		LATERAL
		(
		VALUES
		(d),
		(factor / d)
		) p (f)
	WHERE	f NOT IN (initial, 1)
	),
	factors AS
	(
	SELECT	initial, factor,
		ROW_NUMBER() OVER (PARTITION BY initial ORDER BY factor) rn
	FROM	all_factors
	WHERE	final
	),
	powerset_factors AS
	(
	SELECT	initial, factor, rn
	FROM	factors
	UNION ALL
	SELECT	p.initial, p.factor * f.factor, f.rn
	FROM	powerset_factors p
	JOIN	factors f
	ON	f.initial = p.initial
		AND f.rn > p.rn
	),
	pairs AS
	(
	SELECT	DISTINCT
		initial, one, two
	FROM	(
		SELECT	initial,
			factor one,
			initial / factor two
		FROM	powerset_factors
		WHERE	initial NOT IN (1, factor)
		) q
	WHERE	one BETWEEN 2 AND 99
		AND two BETWEEN 2 AND 99
		AND one < two
	),
	alis_first AS
	(
	SELECT	initial
	FROM	(
		SELECT	initial, COUNT(DISTINCT (one, two)) alis_first_ways
		FROM	pairs
		GROUP BY
			initial
		) q
	WHERE	alis_first_ways >= 2
	),
	walis_list AS
	(
	SELECT	x
	FROM	generate_series(4, 198) x
	CROSS JOIN
		LATERAL
		generate_series(2, x - 2) y
	LEFT JOIN
		alis_first
	ON	initial = y * (x - y)
	GROUP BY
		x
	HAVING	COUNT(*) = COUNT(initial)
	),
	alis_second AS
	(
	SELECT	initial AS ali, one, two, one + two AS wali
	FROM	(
		SELECT	initial, one, two,
			COUNT(*) OVER (PARTITION BY initial) cnt
		FROM	pairs
		WHERE	initial IN
			(
			SELECT	initial
			FROM	alis_first
			)
			AND (one + two) IN
			(
			SELECT	x
			FROM	walis_list
			)
		) q
	WHERE	cnt = 1
	),
	walis_second AS
	(
	SELECT	ali, one, two, wali
	FROM	(
		SELECT	*,
			COUNT(*) OVER (PARTITION BY wali) cnt
		FROM	alis_second
		) q
	WHERE	cnt = 1
	)
SELECT	*
FROM	walis_second
ORDER BY
	wali
