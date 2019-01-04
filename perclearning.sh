#!/usr/bin/bash

#####################
#Perceptron learning#
#####################

EPS=0.001 #machine epsilon
NI=0.2 #learning step length

declare -A dataset
declare -a weights

function read_dataset() {
	local i=0
	local j
	while read -r line ; do
		[[ "${line:0:1}" == "#" ]] && continue
		j=0
		for val in $line ; do
			dataset[$i,$j]=$val
			((j++))
		done
		((i++))
	done < $1

	dims=$((j-1))
	size=$((i))
}

function perceptron_init() {
	weights=($(
		for (( i=0 ; i<=dims ; i++ )) ; do
			echo $((RANDOM % 2 -1)) ; 
		done)
	)
}

function sign() {
	sign_ret=$(bc -l <<< "if ($1 < 0) print -1 else print 1")
}

function abs() {
	abs_ret=$(bc -l <<< "if ($1 < 0) print -($1) else print $1")
}

function start_learning() {
	local converged=1
	while (( converged )) ; do
		echo "Step"
		converged=0
		for (( i=0 ; i<size ; i++ )) ; do
			local out_i=0
			for (( j=0 ; j<dims ; j++ )) ; do
				out_i=$(bc -l <<< "$out_i+${dataset[$i,$j]}*${weights[$j]}")
			done
			out_i=$(bc -l <<< "$out_i + ${weights[$dims]}")
			sign $out_i
			local delta=$(bc -l <<< "${dataset[$i,$dims]} - $sign_ret")
			abs $delta
			if (( $(bc -l <<<  "$abs_ret > $EPS") )) ; then
				converged=1
				for (( j=0 ; j<dims ; j++ )) ; do
					weights[$j]=$(bc -l <<< "${weights[$j]} + $NI*${dataset[$i,$j]}*$delta")
				done
				weights[$dims]=$(bc -l <<< "${weights[$dims]} + $NI*$delta")
			fi
		done
	done
}

function write_file() {
	echo "#!/usr/bin/bc -lq" > $1
	for (( i=0 ; i<=dims ; i++ )) ; do
		echo "w[$i]=${weights[i]}" >> $1
	done

	echo "for (i=0; i<$dims; i++) {
	x[i]=read()
}" >> $1

	echo "y=0
for (i=0; i<$dims; i++) {
	y+=w[i]*x[i]
}
y+=w[$dims]
if (y>0) print 1 else print -1
print \"\\n\"	
quit" >> $1
}


read_dataset $1
perceptron_init
start_learning
write_file $2

