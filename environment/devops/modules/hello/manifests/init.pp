class { 'file':
	content => template('hello/${title}'),
	owner => apache,
	group => apache,
}