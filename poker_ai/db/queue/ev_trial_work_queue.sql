BEGIN
	DBMS_AQADM.CREATE_QUEUE_TABLE(
		queue_table        => 'ev_trial_work_queue_tbl',
		queue_payload_type => 't_row_evolution_trial_queue'
	);
	
	DBMS_AQADM.CREATE_QUEUE(
		queue_name  => 'ev_trial_work_queue',
		queue_table => 'ev_trial_work_queue_tbl'
	);
	
	DBMS_AQADM.START_QUEUE(queue_name => 'ev_trial_work_queue');
END;
