#!/bin/bash
#!/bin/bash
#Script to run the two codes (ATIM and COM window, respectively)
#that implement the M2MMAC simulation. Most parameters are configured once in the beginning. 
#Along with the number of negotiations in the ATIM window and the number of data packets in the COM window,
#The number of packet transmission failures is also counted in both simulations
echo Iniciando a simulacao
echo "Ja alterou Cwmin, CwMax, DIFS, SIFS e cia?"
START_TIME=$SECONDS

#CONFIGS
COUNTER=1
nRuns=20
nStas=5
programatim=""atimwindow""
SIMSTART=1.00
SIMEND=1.06
M=25
nSched=0
B=5
programcom="comwindow"
echo "Serao $nRuns rodadas de $programatim e $programcom com $nStas nos:"

TOTALTX=0
TOTALSCHEDD=0
TOTALCOLLISIONATIM=0
TOTALCOLLISIONCOM=0
rm resumo.out
rm datatx.out
rm handshakefile.out
rm resumocoliatim.out
rm resumocolicom.out
while [ $COUNTER -le $nRuns ]
do
    echo "Run=$COUNTER"
    ./waf --run "scratch/$programatim --nStas=$nStas --nRuns=$COUNTER" > log.out 2>&1   
    cat log.out | grep "HANDSHAKE" --count >> resumo.out
    cat log.out | grep "COLISION" --count >> resumocoliatim.out
    cat log.out | grep -e "HANDSHAKE" -e "NACKSHAKE" -e "SAMECHANNEL" >> handshakefile.out
    TOTALSCHEDD=$(($TOTALSCHEDD+$(cat log.out | grep "HANDSHAKE" --count)))
    nSched=$(cat log.out | grep "HANDSHAKE" --count)
    TOTALCOLLISIONATIM=$(($TOTALCOLLISIONATIM+$(cat log.out | grep "COLISION" --count)))
    nSched=$(echo "scale=5; ($nSched*2)" | bc) #just for information, it is not actually used in the com simulation

    echo "$nSched streams agendados"
    ./waf --run "scratch/$programcom --nStas=$nStas --M=$M --B=$B --nSched=$nSched --nRuns=$COUNTER --simStart=$SIMSTART --simEnd=$SIMEND" > CommLog.out 2>&1 
    cat CommLog.out | grep "DATATX" --count >> datatx.out 
    cat CommLog.out | grep "COLISION" --count >> resumocolicom.out 
    TOTALTX=$(($TOTALTX+$(cat CommLog.out | grep "DATATX" --count)))
    TOTALCOLLISIONCOM=$(($TOTALCOLLISIONCOM+$(cat CommLog.out | grep "COLISION" --count)))
    rm handshakefile.out
    ((COUNTER++))
done
rm log.out
cat resumo.out
echo "Colision Atim:"
cat resumocoliatim.out
echo "Total em todas as rodadas"
echo "$TOTALSCHEDD"
MEDIA=$(echo "scale=5; ($TOTALSCHEDD/$nRuns)" | bc)
echo "Media por rodada"
echo $MEDIA
echo "Numero maximo de streams"
echo "nSched = $(echo "scale=1;($MEDIA*2)" | bc)"

echo "Total colisoes em todas as rodadas"
echo "$TOTALCOLLISIONATIM"
MEDIACOLISIONATIM=$(echo "scale=5; ($TOTALCOLLISIONATIM/$nRuns)" | bc)
echo "Media de colisoes por rodada"
echo $MEDIACOLISIONATIM

rm CommLog.out
cat datatx.out
echo "Colision Com:"
cat resumocolicom.out
echo "Total em todas as rodadas"
echo "$TOTALTX"
PACOTES=$(echo "scale=5; ($TOTALTX/$nRuns)" | bc)
echo "Media de Pacotes por rodada"
echo $PACOTES
echo
echo "Throughput"
THROUGHPUT=$(echo "scale=5; ($PACOTES*512*8*10/1000000)"| bc)
echo "$THROUGHPUT Mbps"

echo "Total colisoes em todas as rodadas"
echo "$TOTALCOLLISIONCOM"
MEDIACOLISIONCOM=$(echo "scale=5; ($TOTALCOLLISIONCOM/$nRuns)" | bc)
echo "Media de colisoes por rodada"
echo $MEDIACOLISIONCOM

#CONFIGS
COUNTER=1
nStas=10

echo "Serao $nRuns rodadas de $programatim e $programcom com $nStas nos:"

TOTALTX=0
TOTALSCHEDD=0
TOTALCOLLISIONATIM=0
TOTALCOLLISIONCOM=0
rm resumo.out
rm datatx.out
rm handshakefile.out
rm resumocoliatim.out
rm resumocolicom.out
while [ $COUNTER -le $nRuns ]
do
    echo "Run=$COUNTER"
    ./waf --run "scratch/$programatim --nStas=$nStas --nRuns=$COUNTER" > log.out 2>&1   
    cat log.out | grep "HANDSHAKE" --count >> resumo.out
    cat log.out | grep "COLISION" --count >> resumocoliatim.out
    cat log.out | grep -e "HANDSHAKE" -e "NACKSHAKE" -e "SAMECHANNEL" >> handshakefile.out
    TOTALSCHEDD=$(($TOTALSCHEDD+$(cat log.out | grep "HANDSHAKE" --count)))
    nSched=$(cat log.out | grep "HANDSHAKE" --count)
    TOTALCOLLISIONATIM=$(($TOTALCOLLISIONATIM+$(cat log.out | grep "COLISION" --count)))
    nSched=$(echo "scale=5; ($nSched*2)" | bc)

    echo "$nSched streams agendados"
    ./waf --run "scratch/$programcom --nStas=$nStas --M=$M --B=$B --nSched=$nSched --nRuns=$COUNTER --simStart=$SIMSTART --simEnd=$SIMEND" > CommLog.out 2>&1 
    cat CommLog.out | grep "DATATX" --count >> datatx.out 
    cat CommLog.out | grep "COLISION" --count >> resumocolicom.out 
    TOTALTX=$(($TOTALTX+$(cat CommLog.out | grep "DATATX" --count)))
    TOTALCOLLISIONCOM=$(($TOTALCOLLISIONCOM+$(cat CommLog.out | grep "COLISION" --count)))
    rm handshakefile.out
    ((COUNTER++))
done
rm log.out
cat resumo.out
echo "Colision Atim:"
cat resumocoliatim.out
echo "Total em todas as rodadas"
echo "$TOTALSCHEDD"
MEDIA=$(echo "scale=5; ($TOTALSCHEDD/$nRuns)" | bc)
echo "Media por rodada"
echo $MEDIA
echo "Numero maximo de streams"
echo "nSched = $(echo "scale=1;($MEDIA*2)" | bc)"

echo "Total colisoes em todas as rodadas"
echo "$TOTALCOLLISIONATIM"
MEDIACOLISIONATIM=$(echo "scale=5; ($TOTALCOLLISIONATIM/$nRuns)" | bc)
echo "Media de colisoes por rodada"
echo $MEDIACOLISIONATIM

rm CommLog.out
cat datatx.out
echo "Colision Com:"
cat resumocolicom.out
echo "Total em todas as rodadas"
echo "$TOTALTX"
PACOTES=$(echo "scale=5; ($TOTALTX/$nRuns)" | bc)
echo "Media de Pacotes por rodada"
echo $PACOTES
echo
echo "Throughput"
THROUGHPUT=$(echo "scale=5; ($PACOTES*512*8*10/1000000)"| bc)
echo "$THROUGHPUT Mbps"

echo "Total colisoes em todas as rodadas"
echo "$TOTALCOLLISIONCOM"
MEDIACOLISIONCOM=$(echo "scale=5; ($TOTALCOLLISIONCOM/$nRuns)" | bc)
echo "Media de colisoes por rodada"
echo $MEDIACOLISIONCOM

#CONFIGS
COUNTER=1
nStas=15

echo "Serao $nRuns rodadas de $programatim e $programcom com $nStas nos:"

TOTALTX=0
TOTALSCHEDD=0
TOTALCOLLISIONATIM=0
TOTALCOLLISIONCOM=0
rm resumo.out
rm datatx.out
rm handshakefile.out
rm resumocoliatim.out
rm resumocolicom.out
while [ $COUNTER -le $nRuns ]
do
    echo "Run=$COUNTER"
    ./waf --run "scratch/$programatim --nStas=$nStas --nRuns=$COUNTER" > log.out 2>&1   
    cat log.out | grep "HANDSHAKE" --count >> resumo.out
    cat log.out | grep "COLISION" --count >> resumocoliatim.out
    cat log.out | grep -e "HANDSHAKE" -e "NACKSHAKE" -e "SAMECHANNEL" >> handshakefile.out
    TOTALSCHEDD=$(($TOTALSCHEDD+$(cat log.out | grep "HANDSHAKE" --count)))
    nSched=$(cat log.out | grep "HANDSHAKE" --count)
    TOTALCOLLISIONATIM=$(($TOTALCOLLISIONATIM+$(cat log.out | grep "COLISION" --count)))
    nSched=$(echo "scale=5; ($nSched*2)" | bc)

    echo "$nSched streams agendados"
    ./waf --run "scratch/$programcom --nStas=$nStas --M=$M --B=$B --nSched=$nSched --nRuns=$COUNTER --simStart=$SIMSTART --simEnd=$SIMEND" > CommLog.out 2>&1 
    cat CommLog.out | grep "DATATX" --count >> datatx.out 
    cat CommLog.out | grep "COLISION" --count >> resumocolicom.out 
    TOTALTX=$(($TOTALTX+$(cat CommLog.out | grep "DATATX" --count)))
    TOTALCOLLISIONCOM=$(($TOTALCOLLISIONCOM+$(cat CommLog.out | grep "COLISION" --count)))
    rm handshakefile.out
    ((COUNTER++))
done
rm log.out
cat resumo.out
echo "Colision Atim:"
cat resumocoliatim.out
echo "Total em todas as rodadas"
echo "$TOTALSCHEDD"
MEDIA=$(echo "scale=5; ($TOTALSCHEDD/$nRuns)" | bc)
echo "Media por rodada"
echo $MEDIA
echo "Numero maximo de streams"
echo "nSched = $(echo "scale=1;($MEDIA*2)" | bc)"

echo "Total colisoes em todas as rodadas"
echo "$TOTALCOLLISIONATIM"
MEDIACOLISIONATIM=$(echo "scale=5; ($TOTALCOLLISIONATIM/$nRuns)" | bc)
echo "Media de colisoes por rodada"
echo $MEDIACOLISIONATIM

rm CommLog.out
cat datatx.out
echo "Colision Com:"
cat resumocolicom.out
echo "Total em todas as rodadas"
echo "$TOTALTX"
PACOTES=$(echo "scale=5; ($TOTALTX/$nRuns)" | bc)
echo "Media de Pacotes por rodada"
echo $PACOTES
echo
echo "Throughput"
THROUGHPUT=$(echo "scale=5; ($PACOTES*512*8*10/1000000)"| bc)
echo "$THROUGHPUT Mbps"

echo "Total colisoes em todas as rodadas"
echo "$TOTALCOLLISIONCOM"
MEDIACOLISIONCOM=$(echo "scale=5; ($TOTALCOLLISIONCOM/$nRuns)" | bc)
echo "Media de colisoes por rodada"
echo $MEDIACOLISIONCOM

#CONFIGS
COUNTER=1
nStas=20

echo "Serao $nRuns rodadas de $programatim e $programcom com $nStas nos:"

TOTALTX=0
TOTALSCHEDD=0
TOTALCOLLISIONATIM=0
TOTALCOLLISIONCOM=0
rm resumo.out
rm datatx.out
rm handshakefile.out
rm resumocoliatim.out
rm resumocolicom.out
while [ $COUNTER -le $nRuns ]
do
    echo "Run=$COUNTER"
    ./waf --run "scratch/$programatim --nStas=$nStas --nRuns=$COUNTER" > log.out 2>&1   
    cat log.out | grep "HANDSHAKE" --count >> resumo.out
    cat log.out | grep "COLISION" --count >> resumocoliatim.out
    cat log.out | grep -e "HANDSHAKE" -e "NACKSHAKE" -e "SAMECHANNEL" >> handshakefile.out
    TOTALSCHEDD=$(($TOTALSCHEDD+$(cat log.out | grep "HANDSHAKE" --count)))
    nSched=$(cat log.out | grep "HANDSHAKE" --count)
    TOTALCOLLISIONATIM=$(($TOTALCOLLISIONATIM+$(cat log.out | grep "COLISION" --count)))
    nSched=$(echo "scale=5; ($nSched*2)" | bc)

    echo "$nSched streams agendados"
    ./waf --run "scratch/$programcom --nStas=$nStas --M=$M --B=$B --nSched=$nSched --nRuns=$COUNTER --simStart=$SIMSTART --simEnd=$SIMEND" > CommLog.out 2>&1 
    cat CommLog.out | grep "DATATX" --count >> datatx.out 
    cat CommLog.out | grep "COLISION" --count >> resumocolicom.out 
    TOTALTX=$(($TOTALTX+$(cat CommLog.out | grep "DATATX" --count)))
    TOTALCOLLISIONCOM=$(($TOTALCOLLISIONCOM+$(cat CommLog.out | grep "COLISION" --count)))
    rm handshakefile.out
    ((COUNTER++))
done
rm log.out
cat resumo.out
echo "Colision Atim:"
cat resumocoliatim.out
echo "Total em todas as rodadas"
echo "$TOTALSCHEDD"
MEDIA=$(echo "scale=5; ($TOTALSCHEDD/$nRuns)" | bc)
echo "Media por rodada"
echo $MEDIA
echo "Numero maximo de streams"
echo "nSched = $(echo "scale=1;($MEDIA*2)" | bc)"

echo "Total colisoes em todas as rodadas"
echo "$TOTALCOLLISIONATIM"
MEDIACOLISIONATIM=$(echo "scale=5; ($TOTALCOLLISIONATIM/$nRuns)" | bc)
echo "Media de colisoes por rodada"
echo $MEDIACOLISIONATIM

rm CommLog.out
cat datatx.out
echo "Colision Com:"
cat resumocolicom.out
echo "Total em todas as rodadas"
echo "$TOTALTX"
PACOTES=$(echo "scale=5; ($TOTALTX/$nRuns)" | bc)
echo "Media de Pacotes por rodada"
echo $PACOTES
echo
echo "Throughput"
THROUGHPUT=$(echo "scale=5; ($PACOTES*512*8*10/1000000)"| bc)
echo "$THROUGHPUT Mbps"

echo "Total colisoes em todas as rodadas"
echo "$TOTALCOLLISIONCOM"
MEDIACOLISIONCOM=$(echo "scale=5; ($TOTALCOLLISIONCOM/$nRuns)" | bc)
echo "Media de colisoes por rodada"
echo $MEDIACOLISIONCOM

#CONFIGS
COUNTER=1
nStas=25

echo "Serao $nRuns rodadas de $programatim e $programcom com $nStas nos:"

TOTALTX=0
TOTALSCHEDD=0
TOTALCOLLISIONATIM=0
TOTALCOLLISIONCOM=0
rm resumo.out
rm datatx.out
rm handshakefile.out
rm resumocoliatim.out
rm resumocolicom.out
while [ $COUNTER -le $nRuns ]
do
    echo "Run=$COUNTER"
    ./waf --run "scratch/$programatim --nStas=$nStas --nRuns=$COUNTER" > log.out 2>&1   
    cat log.out | grep "HANDSHAKE" --count >> resumo.out
    cat log.out | grep "COLISION" --count >> resumocoliatim.out
    cat log.out | grep -e "HANDSHAKE" -e "NACKSHAKE" -e "SAMECHANNEL" >> handshakefile.out
    TOTALSCHEDD=$(($TOTALSCHEDD+$(cat log.out | grep "HANDSHAKE" --count)))
    nSched=$(cat log.out | grep "HANDSHAKE" --count)
    TOTALCOLLISIONATIM=$(($TOTALCOLLISIONATIM+$(cat log.out | grep "COLISION" --count)))
    nSched=$(echo "scale=5; ($nSched*2)" | bc)

    echo "$nSched streams agendados"
    ./waf --run "scratch/$programcom --nStas=$nStas --M=$M --B=$B --nSched=$nSched --nRuns=$COUNTER --simStart=$SIMSTART --simEnd=$SIMEND" > CommLog.out 2>&1 
    cat CommLog.out | grep "DATATX" --count >> datatx.out 
    cat CommLog.out | grep "COLISION" --count >> resumocolicom.out 
    TOTALTX=$(($TOTALTX+$(cat CommLog.out | grep "DATATX" --count)))
    TOTALCOLLISIONCOM=$(($TOTALCOLLISIONCOM+$(cat CommLog.out | grep "COLISION" --count)))
    rm handshakefile.out
    ((COUNTER++))
done
rm log.out
cat resumo.out
echo "Colision Atim:"
cat resumocoliatim.out
echo "Total em todas as rodadas"
echo "$TOTALSCHEDD"
MEDIA=$(echo "scale=5; ($TOTALSCHEDD/$nRuns)" | bc)
echo "Media por rodada"
echo $MEDIA
echo "Numero maximo de streams"
echo "nSched = $(echo "scale=1;($MEDIA*2)" | bc)"

echo "Total colisoes em todas as rodadas"
echo "$TOTALCOLLISIONATIM"
MEDIACOLISIONATIM=$(echo "scale=5; ($TOTALCOLLISIONATIM/$nRuns)" | bc)
echo "Media de colisoes por rodada"
echo $MEDIACOLISIONATIM

rm CommLog.out
cat datatx.out
echo "Colision Com:"
cat resumocolicom.out
echo "Total em todas as rodadas"
echo "$TOTALTX"
PACOTES=$(echo "scale=5; ($TOTALTX/$nRuns)" | bc)
echo "Media de Pacotes por rodada"
echo $PACOTES
echo
echo "Throughput"
THROUGHPUT=$(echo "scale=5; ($PACOTES*512*8*10/1000000)"| bc)
echo "$THROUGHPUT Mbps"

echo "Total colisoes em todas as rodadas"
echo "$TOTALCOLLISIONCOM"
MEDIACOLISIONCOM=$(echo "scale=5; ($TOTALCOLLISIONCOM/$nRuns)" | bc)
echo "Media de colisoes por rodada"
echo $MEDIACOLISIONCOM

#CONFIGS
COUNTER=1
nStas=30

echo "Serao $nRuns rodadas de $programatim e $programcom com $nStas nos:"

TOTALTX=0
TOTALSCHEDD=0
TOTALCOLLISIONATIM=0
TOTALCOLLISIONCOM=0
rm resumo.out
rm datatx.out
rm handshakefile.out
rm resumocoliatim.out
rm resumocolicom.out
while [ $COUNTER -le $nRuns ]
do
    echo "Run=$COUNTER"
    ./waf --run "scratch/$programatim --nStas=$nStas --nRuns=$COUNTER" > log.out 2>&1   
    cat log.out | grep "HANDSHAKE" --count >> resumo.out
    cat log.out | grep "COLISION" --count >> resumocoliatim.out
    cat log.out | grep -e "HANDSHAKE" -e "NACKSHAKE" -e "SAMECHANNEL" >> handshakefile.out
    TOTALSCHEDD=$(($TOTALSCHEDD+$(cat log.out | grep "HANDSHAKE" --count)))
    nSched=$(cat log.out | grep "HANDSHAKE" --count)
    TOTALCOLLISIONATIM=$(($TOTALCOLLISIONATIM+$(cat log.out | grep "COLISION" --count)))
    nSched=$(echo "scale=5; ($nSched*2)" | bc)

    echo "$nSched streams agendados"
    ./waf --run "scratch/$programcom --nStas=$nStas --M=$M --B=$B --nSched=$nSched --nRuns=$COUNTER --simStart=$SIMSTART --simEnd=$SIMEND" > CommLog.out 2>&1 
    cat CommLog.out | grep "DATATX" --count >> datatx.out 
    cat CommLog.out | grep "COLISION" --count >> resumocolicom.out 
    TOTALTX=$(($TOTALTX+$(cat CommLog.out | grep "DATATX" --count)))
    TOTALCOLLISIONCOM=$(($TOTALCOLLISIONCOM+$(cat CommLog.out | grep "COLISION" --count)))
    rm handshakefile.out
    ((COUNTER++))
done
rm log.out
cat resumo.out
echo "Colision Atim:"
cat resumocoliatim.out
echo "Total em todas as rodadas"
echo "$TOTALSCHEDD"
MEDIA=$(echo "scale=5; ($TOTALSCHEDD/$nRuns)" | bc)
echo "Media por rodada"
echo $MEDIA
echo "Numero maximo de streams"
echo "nSched = $(echo "scale=1;($MEDIA*2)" | bc)"

echo "Total colisoes em todas as rodadas"
echo "$TOTALCOLLISIONATIM"
MEDIACOLISIONATIM=$(echo "scale=5; ($TOTALCOLLISIONATIM/$nRuns)" | bc)
echo "Media de colisoes por rodada"
echo $MEDIACOLISIONATIM

rm CommLog.out
cat datatx.out
echo "Colision Com:"
cat resumocolicom.out
echo "Total em todas as rodadas"
echo "$TOTALTX"
PACOTES=$(echo "scale=5; ($TOTALTX/$nRuns)" | bc)
echo "Media de Pacotes por rodada"
echo $PACOTES
echo
echo "Throughput"
THROUGHPUT=$(echo "scale=5; ($PACOTES*512*8*10/1000000)"| bc)
echo "$THROUGHPUT Mbps"

echo "Total colisoes em todas as rodadas"
echo "$TOTALCOLLISIONCOM"
MEDIACOLISIONCOM=$(echo "scale=5; ($TOTALCOLLISIONCOM/$nRuns)" | bc)
echo "Media de colisoes por rodada"

#CONFIGS
COUNTER=1
nStas=35

echo "Serao $nRuns rodadas de $programatim e $programcom com $nStas nos:"

TOTALTX=0
TOTALSCHEDD=0
TOTALCOLLISIONATIM=0
TOTALCOLLISIONCOM=0
rm resumo.out
rm datatx.out
rm handshakefile.out
rm resumocoliatim.out
rm resumocolicom.out
while [ $COUNTER -le $nRuns ]
do
    echo "Run=$COUNTER"
    ./waf --run "scratch/$programatim --nStas=$nStas --nRuns=$COUNTER" > log.out 2>&1   
    cat log.out | grep "HANDSHAKE" --count >> resumo.out
    cat log.out | grep "COLISION" --count >> resumocoliatim.out
    cat log.out | grep -e "HANDSHAKE" -e "NACKSHAKE" -e "SAMECHANNEL" >> handshakefile.out
    TOTALSCHEDD=$(($TOTALSCHEDD+$(cat log.out | grep "HANDSHAKE" --count)))
    nSched=$(cat log.out | grep "HANDSHAKE" --count)
    TOTALCOLLISIONATIM=$(($TOTALCOLLISIONATIM+$(cat log.out | grep "COLISION" --count)))
    nSched=$(echo "scale=5; ($nSched*2)" | bc)

    echo "$nSched streams agendados"
    ./waf --run "scratch/$programcom --nStas=$nStas --M=$M --B=$B --nSched=$nSched --nRuns=$COUNTER --simStart=$SIMSTART --simEnd=$SIMEND" > CommLog.out 2>&1 
    cat CommLog.out | grep "DATATX" --count >> datatx.out 
    cat CommLog.out | grep "COLISION" --count >> resumocolicom.out 
    TOTALTX=$(($TOTALTX+$(cat CommLog.out | grep "DATATX" --count)))
    TOTALCOLLISIONCOM=$(($TOTALCOLLISIONCOM+$(cat CommLog.out | grep "COLISION" --count)))
    rm handshakefile.out
    ((COUNTER++))
done
rm log.out
cat resumo.out
echo "Colision Atim:"
cat resumocoliatim.out
echo "Total em todas as rodadas"
echo "$TOTALSCHEDD"
MEDIA=$(echo "scale=5; ($TOTALSCHEDD/$nRuns)" | bc)
echo "Media por rodada"
echo $MEDIA
echo "Numero maximo de streams"
echo "nSched = $(echo "scale=1;($MEDIA*2)" | bc)"

echo "Total colisoes em todas as rodadas"
echo "$TOTALCOLLISIONATIM"
MEDIACOLISIONATIM=$(echo "scale=5; ($TOTALCOLLISIONATIM/$nRuns)" | bc)
echo "Media de colisoes por rodada"
echo $MEDIACOLISIONATIM

rm CommLog.out
cat datatx.out
echo "Colision Com:"
cat resumocolicom.out
echo "Total em todas as rodadas"
echo "$TOTALTX"
PACOTES=$(echo "scale=5; ($TOTALTX/$nRuns)" | bc)
echo "Media de Pacotes por rodada"
echo $PACOTES
echo
echo "Throughput"
THROUGHPUT=$(echo "scale=5; ($PACOTES*512*8*10/1000000)"| bc)
echo "$THROUGHPUT Mbps"

echo "Total colisoes em todas as rodadas"
echo "$TOTALCOLLISIONCOM"
MEDIACOLISIONCOM=$(echo "scale=5; ($TOTALCOLLISIONCOM/$nRuns)" | bc)
echo "Media de colisoes por rodada"

#CONFIGS
COUNTER=1
nStas=40

echo "Serao $nRuns rodadas de $programatim e $programcom com $nStas nos:"

TOTALTX=0
TOTALSCHEDD=0
TOTALCOLLISIONATIM=0
TOTALCOLLISIONCOM=0
rm resumo.out
rm datatx.out
rm handshakefile.out
rm resumocoliatim.out
rm resumocolicom.out
while [ $COUNTER -le $nRuns ]
do
    echo "Run=$COUNTER"
    ./waf --run "scratch/$programatim --nStas=$nStas --nRuns=$COUNTER" > log.out 2>&1   
    cat log.out | grep "HANDSHAKE" --count >> resumo.out
    cat log.out | grep "COLISION" --count >> resumocoliatim.out
    cat log.out | grep -e "HANDSHAKE" -e "NACKSHAKE" -e "SAMECHANNEL" >> handshakefile.out
    TOTALSCHEDD=$(($TOTALSCHEDD+$(cat log.out | grep "HANDSHAKE" --count)))
    nSched=$(cat log.out | grep "HANDSHAKE" --count)
    TOTALCOLLISIONATIM=$(($TOTALCOLLISIONATIM+$(cat log.out | grep "COLISION" --count)))
    nSched=$(echo "scale=5; ($nSched*2)" | bc)

    echo "$nSched streams agendados"
    ./waf --run "scratch/$programcom --nStas=$nStas --M=$M --B=$B --nSched=$nSched --nRuns=$COUNTER --simStart=$SIMSTART --simEnd=$SIMEND" > CommLog.out 2>&1 
    cat CommLog.out | grep "DATATX" --count >> datatx.out 
    cat CommLog.out | grep "COLISION" --count >> resumocolicom.out 
    TOTALTX=$(($TOTALTX+$(cat CommLog.out | grep "DATATX" --count)))
    TOTALCOLLISIONCOM=$(($TOTALCOLLISIONCOM+$(cat CommLog.out | grep "COLISION" --count)))
    rm handshakefile.out
    ((COUNTER++))
done
rm log.out
cat resumo.out
echo "Colision Atim:"
cat resumocoliatim.out
echo "Total em todas as rodadas"
echo "$TOTALSCHEDD"
MEDIA=$(echo "scale=5; ($TOTALSCHEDD/$nRuns)" | bc)
echo "Media por rodada"
echo $MEDIA
echo "Numero maximo de streams"
echo "nSched = $(echo "scale=1;($MEDIA*2)" | bc)"

echo "Total colisoes em todas as rodadas"
echo "$TOTALCOLLISIONATIM"
MEDIACOLISIONATIM=$(echo "scale=5; ($TOTALCOLLISIONATIM/$nRuns)" | bc)
echo "Media de colisoes por rodada"
echo $MEDIACOLISIONATIM

rm CommLog.out
cat datatx.out
echo "Colision Com:"
cat resumocolicom.out
echo "Total em todas as rodadas"
echo "$TOTALTX"
PACOTES=$(echo "scale=5; ($TOTALTX/$nRuns)" | bc)
echo "Media de Pacotes por rodada"
echo $PACOTES
echo
echo "Throughput"
THROUGHPUT=$(echo "scale=5; ($PACOTES*512*8*10/1000000)"| bc)
echo "$THROUGHPUT Mbps"

echo "Total colisoes em todas as rodadas"
echo "$TOTALCOLLISIONCOM"
MEDIACOLISIONCOM=$(echo "scale=5; ($TOTALCOLLISIONCOM/$nRuns)" | bc)
echo "Media de colisoes por rodada"


echo $MEDIACOLISIONCOM
ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo "Tempo decorrido"
echo "$(($ELAPSED_TIME/60)) min $(($ELAPSED_TIME%60)) sec"
echo Finalizando a simulacao