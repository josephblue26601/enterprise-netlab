.PHONY: deploy destroy verify backup health monitor exporter failover

deploy:
	sudo containerlab deploy -t topology.clab.yml

destroy:
	sudo containerlab destroy -t topology.clab.yml --cleanup

verify:
	bash tests/verify.sh

backup:
	cd automation && python3 backup_configs.py

health:
	cd automation && python3 health_check.py

exporter:
	cd automation && python3 exporter.py

monitor:
	docker compose -f monitoring/docker-compose.yml up -d
	@echo "Grafana: http://localhost:3000 (admin/admin)"

failover:
	bash tests/failover_test.sh
