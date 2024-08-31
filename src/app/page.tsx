"use client"
import { ethers } from "ethers";
import Image from "next/image";
import { useEffect, useMemo, useState } from "react";
import  abi from "./../contracts/HaverVoting.json";
import Clanes from "@/components/Clanes";
import ClanInfo from "@/components/OurClan";
export interface Clan {
  id: number;
  name: string;
  leader: string;
  members: string[];
  lastVoteTime: number;
  lastVoteEndTime: number;
}

export default function Home() {
  
  const abiVoting = abi;
  const [provider, setProvider] = useState<ethers.Provider | null>(null);
  const [account, setAccount] = useState('');
  const [contract, setContract] = useState<ethers.Contract | null>(null);
  const [signer, setSigner] = useState<ethers.Signer | null>(null);


  const [userClanId, setUserClanId] = useState<number | null>(null);
  const [clanes, setClanes ] = useState<Clan[]>([]);
  const [leader, setLeader] = useState('')
  // const [accountClan, setAccountClan] = useState<null | Clan >(null);


  useEffect(() => {
    const init = async () => {
      const address = '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9';
      const abiVoting : any = abi.abi;

      const { BrowserProvider} : any = ethers;
      const { ethereum } : any = window;
      try {
        // const { ethereum } = window;
        if(!ethereum) return
        const account = await ethereum.request({
          method:"eth_requestAccounts"
        })
 
        ethereum.on("accountsChanged",()=>{
         window.location.reload()
        })
        const provider = new BrowserProvider(ethereum); //read the Blockchain    
        const signer = await provider.getSigner(); //write the blockchain
        // console.log(await signer.getAddress()); 
        setAccount(account);
        setProvider(provider);
        setSigner(signer);


        const contract = new ethers.Contract(
          address,
          abiVoting,
          signer
        )
        setContract(contract);
      } catch (error) {
        console.log(error);
        
      }
    };
    init();
  }, []);

  // console.log(contract);

  useEffect(() => {
    async function getClanes(){
      try {
        if(!contract) return;
      
        const [ids, names, leaders, members, lastVoteTimes, lastVoteEndTimes] = await contract.getAllClans();
        
        if(!ids || ids.length == 0) return;
        const clanesMapped : Clan[] = ids.map((id: number, index: number) => ({
            id,
            name: names[index],
            leader: leaders[index],
            members: members[index],
            lastVoteTime: Number(lastVoteTimes[index]), // Convert BigNumber to number
            lastVoteEndTime: Number(lastVoteEndTimes[index]), // Convert BigNumber to number
        }));
        
        setClanes(clanesMapped)
        
      } catch (error) {
        console.log(error);
        
      }
    }

    if(!contract) return;
    getClanes();
  },[contract])

    const accountClan = useMemo(() => {
        if (!clanes || clanes.length === 0 || !account || account.length === 0) return null;
        const accountClan = clanes.find(clan => 
            clan.leader.toLowerCase() === account[0].toLowerCase() || 
            clan.members.some(mem => mem.toLowerCase() === account[0].toLowerCase())
        );

        return accountClan || null; // Retorna el clan o null si no se encuentra
    }, [account, clanes]);
  
  // console.log(accountClan);
  
  return (
    <main className="flex h-screen  items-center justify-between border-2  bg-white p-5 ">
      <section className="bg-blue-300 w-1/4 h-full rounded-xl">
          <Clanes clanes={clanes} contract={contract}  />
      </section>
      <section className="bg-blue-600 flex-1 h-full rounded-xl">
          <ClanInfo contract={contract} clan={accountClan}/>
      </section>
    </main>
  );
}
