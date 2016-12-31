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
	)
SELECT	*
FROM	all_factors
WHERE	initial = 96
	AND final
