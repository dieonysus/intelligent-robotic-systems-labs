import os
import subprocess

os.environ["GENOME"] = "0.75,0.77"

proc = subprocess.Popen(
    ["argos3", "-c", "test-controller-params.argos"],
    stdout=subprocess.PIPE,
    text=True
)

fitness = None
for line in proc.stdout:
    if "FITNESS:" in line:
        fitness = str(line.strip().split(":")[1])
        print(fitness)
