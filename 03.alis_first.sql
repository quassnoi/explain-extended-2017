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
	SELECT	initial,
		(LEAST(one, two), GREATEST(one, two)) pair
	FROM	(
		SELECT	initial,
			factor one,
			initial / factor two
		FROM	powerset_factors
		WHERE	initial NOT IN (1, factor)
		) q
	WHERE	one BETWEEN 2 AND 99
		AND two BETWEEN 2 AND 99
	),
	alis_first AS
	(
	SELECT	*
	FROM	(
		SELECT	initial, COUNT(DISTINCT pair) alis_first_ways
		FROM	pairs
		GROUP BY
			initial
		) q
	WHERE	alis_first_ways >= 2
	)
SELECT	'   ' || STRING_AGG(CASE WHEN x % 10 = 0 THEN (x / 10)::TEXT ELSE ' ' END, '')
FROM	generate_series(0, 99) x
UNION ALL
SELECT	'   ' || STRING_AGG((x % 10)::TEXT, '')
FROM	generate_series(0, 99) x
UNION ALL
(
SELECT	LPAD(y::TEXT, 2, '0') || ' ' || STRING_AGG(CASE WHEN alis_first_ways IS NOT NULL THEN '.' ELSE ' ' END, '' ORDER BY x)
FROM	generate_series(0, 99) y
CROSS JOIN
	generate_series(0, 99) x
LEFT JOIN
	alis_first
ON	initial = (y * 100) + x
GROUP BY
	y
ORDER BY
	y
)
